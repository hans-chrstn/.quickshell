#pragma once

#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>
#include <memory>

class DisplayPowerObserver : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool available READ available NOTIFY stateChanged)
    Q_PROPERTY(QVariantMap screens READ screens NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)
  public:
    explicit DisplayPowerObserver(QObject *parent = nullptr);
    ~DisplayPowerObserver() override;
    bool enabled() const {
        return m_enabled;
    }
    void setEnabled(bool enabled);
    bool available() const;
    QVariantMap screens() const;
    QString error() const {
        return m_error;
    }
  signals:
    void enabledChanged();
    void stateChanged();

  private:
    struct Connection;
    std::unique_ptr<Connection> m_connection;
    bool m_enabled = false;
    QString m_error;
    void fail(const QString &error);
};
