#include "power-client.h"
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <memory>
#include <string>
#include <vector>
#include <wayland-client.h>

struct Output {
    uint32_t id;
    wl_output *output = nullptr;
    zwlr_output_power_v1 *power = nullptr;
    std::string name;
    bool known = false;
    ~Output() {
        if (power)
            zwlr_output_power_v1_destroy(power);
        if (output)
            wl_output_release(output);
    }
};

static zwlr_output_power_manager_v1 *manager = nullptr;
static uint32_t managerId = 0;
static std::vector<std::unique_ptr<Output>> outputs;
static const zwlr_output_power_v1_listener powerListener = {
    [](void *data, zwlr_output_power_v1 *, uint32_t mode) {
        auto &o = *static_cast<Output *>(data);
        std::printf("%s id=%u name=%s power=%s\n", o.known ? "changed" : "initial", o.id, o.name.c_str(),
                    mode == 1 ? "on" : "off");
        o.known = true;
    },
    [](void *data, zwlr_output_power_v1 *power) {
        auto &o = *static_cast<Output *>(data);
        std::printf("unavailable id=%u name=%s\n", o.id, o.name.c_str());
        zwlr_output_power_v1_destroy(power);
        o.power = nullptr;
        o.known = false;
    }};

static void subscribe(Output &o) {
    if (!manager || o.power)
        return;
    o.power = zwlr_output_power_manager_v1_get_output_power(manager, o.output);
    zwlr_output_power_v1_add_listener(o.power, &powerListener, &o);
}

static const wl_output_listener outputListener = {
    [](void *, wl_output *, int32_t, int32_t, int32_t, int32_t, int32_t, const char *, const char *, int32_t) {},
    [](void *, wl_output *, uint32_t, int32_t, int32_t, int32_t) {},
    [](void *, wl_output *) {},
    [](void *, wl_output *, int32_t) {},
    [](void *data, wl_output *, const char *name) {
        auto &o = *static_cast<Output *>(data);
        o.name = name;
        std::printf("output id=%u name=%s\n", o.id, name);
    },
    [](void *, wl_output *, const char *) {}};

static const wl_registry_listener registryListener = {
    [](void *, wl_registry *registry, uint32_t id, const char *interface, uint32_t version) {
        if (std::strcmp(interface, "zwlr_output_power_manager_v1") == 0) {
            managerId = id;
            manager = static_cast<zwlr_output_power_manager_v1 *>(
                wl_registry_bind(registry, id, &zwlr_output_power_manager_v1_interface, 1));
            std::puts("capability available version=1");
            for (auto &o : outputs)
                subscribe(*o);
        } else if (std::strcmp(interface, "wl_output") == 0) {
            if (version < 4) {
                std::printf("unsupported output=%u requires-wl_output-v4\n", id);
                return;
            }
            auto o = std::make_unique<Output>();
            o->id = id;
            o->output = static_cast<wl_output *>(wl_registry_bind(registry, id, &wl_output_interface, 4));
            wl_output_add_listener(o->output, &outputListener, o.get());
            subscribe(*o);
            outputs.push_back(std::move(o));
        }
    },
    [](void *, wl_registry *, uint32_t id) {
        if (id == managerId) {
            for (auto &o : outputs) {
                if (o->power)
                    zwlr_output_power_v1_destroy(o->power);
                o->power = nullptr;
                o->known = false;
            }
            zwlr_output_power_manager_v1_destroy(manager);
            manager = nullptr;
            std::puts("capability removed");
        }
        std::erase_if(outputs, [id](const auto &o) {
            if (o->id != id)
                return false;
            std::printf("removed id=%u name=%s\n", id, o->name.c_str());
            return true;
        });
    }};

int main() {
    std::setvbuf(stdout, nullptr, _IOLBF, 0);
    auto *display = wl_display_connect(nullptr);
    if (!display) {
        std::perror("wayland connect");
        return 1;
    }
    auto *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registryListener, nullptr);
    int result = 0;
    if (wl_display_roundtrip(display) < 0 || wl_display_roundtrip(display) < 0)
        result = 1;
    else if (!manager) {
        std::puts("capability unavailable");
        result = 2;
    } else {
        std::puts("ready waiting-for-events (no periodic timer)");
        while (wl_display_dispatch(display) >= 0) {
        }
        result = 1;
    }
    outputs.clear();
    if (manager)
        zwlr_output_power_manager_v1_destroy(manager);
    wl_registry_destroy(registry);
    wl_display_disconnect(display);
    return result;
}
