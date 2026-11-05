#include <QObject>
#include <QtQuickTest/quicktest.h>
#include <server.h>

class Setup : public QObject
{
    Q_OBJECT
public Q_SLOTS:
    void applicationAvailable()
    {
        if (!NotificationManager::Server::self().init()) {
            qFatal("Could not own the notification service on the isolated test bus");
        }
    }
};

QUICK_TEST_MAIN_WITH_SETUP(notifications, Setup)
#include "runner.moc"
