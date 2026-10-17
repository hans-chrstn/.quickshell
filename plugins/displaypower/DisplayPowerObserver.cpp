#include "DisplayPowerObserver.h"
#include "power-client.h"
#include <QSocketNotifier>
#include <algorithm>
#include <cerrno>
#include <cstring>
#include <vector>
#include <wayland-client.h>

struct DisplayPowerObserver::Connection {
    struct Output {
        Connection *owner;
        uint32_t id;
        wl_output *output = nullptr;
        zwlr_output_power_v1 *power = nullptr;
        QString name;
        int mode = -1;
        ~Output() {
            if (power)
                zwlr_output_power_v1_destroy(power);
            if (output)
                wl_output_release(output);
        }
    };
    DisplayPowerObserver *owner;
    wl_display *display = nullptr;
    wl_registry *registry = nullptr;
    wl_callback *initialSync = nullptr;
    zwlr_output_power_manager_v1 *manager = nullptr;
    uint32_t managerId = 0;
    std::unique_ptr<QSocketNotifier> reader;
    std::unique_ptr<QSocketNotifier> writer;
    std::vector<std::unique_ptr<Output>> outputs;

    explicit Connection(DisplayPowerObserver *owner) : owner(owner) {}
    ~Connection() {
        reader.reset();
        writer.reset();
        outputs.clear();
        if (initialSync)
            wl_callback_destroy(initialSync);
        if (manager)
            zwlr_output_power_manager_v1_destroy(manager);
        if (registry)
            wl_registry_destroy(registry);
        if (display)
            wl_display_disconnect(display);
    }
    void changed() {
        emit owner->stateChanged();
    }
    void flush() {
        if (wl_display_flush(display) < 0) {
            if (errno == EAGAIN)
                writer->setEnabled(true);
            else
                owner->fail(QStringLiteral("Wayland display-power connection failed"));
        } else
            writer->setEnabled(false);
    }
    void subscribe(Output &o) {
        if (!manager || o.power)
            return;
        static const zwlr_output_power_v1_listener listener = {[](void *data, zwlr_output_power_v1 *, uint32_t mode) {
                                                                   auto &o = *static_cast<Output *>(data);
                                                                   const int next =
                                                                       mode <= 1 ? static_cast<int>(mode) : -1;
                                                                   if (o.mode == next)
                                                                       return;
                                                                   o.mode = next;
                                                                   o.owner->changed();
                                                               },
                                                               [](void *data, zwlr_output_power_v1 *power) {
                                                                   auto &o = *static_cast<Output *>(data);
                                                                   zwlr_output_power_v1_destroy(power);
                                                                   o.power = nullptr;
                                                                   o.mode = -1;
                                                                   o.owner->changed();
                                                               }};
        o.power = zwlr_output_power_manager_v1_get_output_power(manager, o.output);
        zwlr_output_power_v1_add_listener(o.power, &listener, &o);
    }
    bool start() {
        display = wl_display_connect(nullptr);
        if (!display)
            return false;
        registry = wl_display_get_registry(display);
        static const wl_output_listener outputListener = {
            [](void *, wl_output *, int32_t, int32_t, int32_t, int32_t, int32_t, const char *, const char *, int32_t) {
            },
            [](void *, wl_output *, uint32_t, int32_t, int32_t, int32_t) {},
            [](void *, wl_output *) {},
            [](void *, wl_output *, int32_t) {},
            [](void *data, wl_output *, const char *name) {
                auto &o = *static_cast<Output *>(data);
                o.name = QString::fromUtf8(name);
                o.owner->changed();
            },
            [](void *, wl_output *, const char *) {}};
        static const wl_registry_listener registryListener = {
            [](void *data, wl_registry *registry, uint32_t id, const char *interface, uint32_t version) {
                auto &c = *static_cast<Connection *>(data);
                if (std::strcmp(interface, "zwlr_output_power_manager_v1") == 0 && !c.manager) {
                    c.managerId = id;
                    c.manager = static_cast<zwlr_output_power_manager_v1 *>(
                        wl_registry_bind(registry, id, &zwlr_output_power_manager_v1_interface, 1));
                    c.owner->m_error.clear();
                    for (auto &o : c.outputs)
                        c.subscribe(*o);
                    c.changed();
                } else if (std::strcmp(interface, "wl_output") == 0 && version >= 4) {
                    auto o = std::make_unique<Output>();
                    o->owner = &c;
                    o->id = id;
                    o->output = static_cast<wl_output *>(wl_registry_bind(registry, id, &wl_output_interface, 4));
                    wl_output_add_listener(o->output, &outputListener, o.get());
                    c.subscribe(*o);
                    c.outputs.push_back(std::move(o));
                }
            },
            [](void *data, wl_registry *, uint32_t id) {
                auto &c = *static_cast<Connection *>(data);
                if (id == c.managerId && c.manager) {
                    for (auto &o : c.outputs) {
                        if (o->power)
                            zwlr_output_power_v1_destroy(o->power);
                        o->power = nullptr;
                        o->mode = -1;
                    }
                    zwlr_output_power_manager_v1_destroy(c.manager);
                    c.manager = nullptr;
                    c.owner->m_error = QStringLiteral("Display-power protocol removed");
                }
                std::erase_if(c.outputs, [id](const auto &o) { return o->id == id; });
                c.changed();
            }};
        wl_registry_add_listener(registry, &registryListener, this);
        static const wl_callback_listener syncListener = {[](void *data, wl_callback *callback, uint32_t) {
            auto &c = *static_cast<Connection *>(data);
            wl_callback_destroy(callback);
            c.initialSync = nullptr;
            if (!c.manager) {
                c.owner->m_error = QStringLiteral("Display-power protocol unavailable");
                c.changed();
            }
        }};
        initialSync = wl_display_sync(display);
        wl_callback_add_listener(initialSync, &syncListener, this);
        reader = std::make_unique<QSocketNotifier>(wl_display_get_fd(display), QSocketNotifier::Read);
        writer = std::make_unique<QSocketNotifier>(wl_display_get_fd(display), QSocketNotifier::Write);
        writer->setEnabled(false);
        QObject::connect(reader.get(), &QSocketNotifier::activated, owner, [this] {
            if (wl_display_dispatch(display) < 0) {
                owner->fail(QStringLiteral("Wayland display-power connection lost"));
                return;
            }
            flush();
        });
        QObject::connect(writer.get(), &QSocketNotifier::activated, owner, [this] { flush(); });
        flush();
        return true;
    }
};

DisplayPowerObserver::DisplayPowerObserver(QObject *parent) : QObject(parent) {}
DisplayPowerObserver::~DisplayPowerObserver() = default;
void DisplayPowerObserver::setEnabled(bool enabled) {
    if (m_enabled == enabled)
        return;
    m_enabled = enabled;
    m_connection.reset();
    m_error.clear();
    if (enabled) {
        m_connection = std::make_unique<Connection>(this);
        if (!m_connection->start())
            fail(QStringLiteral("Cannot connect to Wayland display"));
    }
    emit enabledChanged();
    emit stateChanged();
}
void DisplayPowerObserver::fail(const QString &error) {
    m_error = error;
    if (m_connection) {
        if (m_connection->reader)
            m_connection->reader->setEnabled(false);
        if (m_connection->writer)
            m_connection->writer->setEnabled(false);
    }
    emit stateChanged();
}
bool DisplayPowerObserver::available() const {
    return m_connection && m_connection->manager && m_error.isEmpty();
}
QVariantMap DisplayPowerObserver::screens() const {
    QVariantMap result;
    if (!available())
        return result;
    for (const auto &o : m_connection->outputs)
        if (!o->name.isEmpty() && o->mode >= 0)
            result.insert(o->name, o->mode == 1);
    return result;
}
