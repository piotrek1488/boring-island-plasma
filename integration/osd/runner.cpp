#include <QObject>
#include <QDBusConnection>
#include <QQmlContext>
#include <QQmlEngine>
#include <QtQuickTest/quicktest.h>

class FixtureDisplay : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.ScreenBrightness.Display")
    Q_PROPERTY(QString Label READ label CONSTANT)
    Q_PROPERTY(bool IsInternal READ isInternal CONSTANT)
    Q_PROPERTY(int Brightness READ brightness)
    Q_PROPERTY(int MaxBrightness READ maximum CONSTANT)
public:
    FixtureDisplay(QString label, int value, int maximum, bool internal)
        : m_label(label), m_brightness(value), m_maximum(maximum), m_internal(internal) {}
    QString label() const { return m_label; }
    bool isInternal() const { return m_internal; }
    int brightness() const { return m_brightness; }
    int maximum() const { return m_maximum; }
    void change(int value) { m_brightness = value; }
    int writes = 0;
public Q_SLOTS:
    void SetBrightnessWithContext(int, uint, const QString &) { ++writes; }
private:
    QString m_label;
    int m_brightness;
    int m_maximum;
    bool m_internal;
};

class BrightnessService : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.ScreenBrightness")
    Q_PROPERTY(QStringList DisplaysDBusNames READ names CONSTANT)
public:
    FixtureDisplay laptop{QStringLiteral("Laptop"), 400, 1000, true};
    FixtureDisplay external{QStringLiteral("External"), 100, 200, false};
    QStringList names() const { return {QStringLiteral("display0"), QStringLiteral("display1")}; }
    Q_INVOKABLE void change(const QString &name, int value)
    {
        (name == QStringLiteral("display0") ? laptop : external).change(value);
        Q_EMIT BrightnessChanged(name, value, QStringLiteral("fixture"), QStringLiteral("slider"));
    }
    Q_INVOKABLE int writeCalls() const { return laptop.writes + external.writes + adjustments; }
public Q_SLOTS:
    void AdjustBrightnessRatio(double, uint) { ++adjustments; }
    void AdjustBrightnessStep(uint, uint) { ++adjustments; }
Q_SIGNALS:
    void BrightnessChanged(const QString &displayName, int value, const QString &sourceClientName, const QString &sourceClientContext);
private:
    int adjustments = 0;
};

class OsdService : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.osdService")
public:
    Q_INVOKABLE void volume(int percent) { Q_EMIT osdProgress(QStringLiteral("audio-volume-high"), percent, 100, QStringLiteral("Speakers")); }
    Q_INVOKABLE void multipleDisplays() { Q_EMIT osdText(QStringLiteral("video-display-brightness"), QStringLiteral("Laptop: 75%\nExternal: 30%")); }
Q_SIGNALS:
    void osdProgress(const QString &icon, int value, int maximum, const QString &description);
    void osdText(const QString &icon, const QString &description);
};

class Setup : public QObject
{
    Q_OBJECT
public Q_SLOTS:
    void applicationAvailable()
    {
        auto bus = QDBusConnection::sessionBus();
        const auto flags = QDBusConnection::ExportAllProperties | QDBusConnection::ExportAllSignals | QDBusConnection::ExportAllSlots;
        if (!bus.registerService(QStringLiteral("org.kde.ScreenBrightness"))
            || !bus.registerObject(QStringLiteral("/org/kde/ScreenBrightness"), &brightness, flags)
            || !bus.registerObject(QStringLiteral("/org/kde/ScreenBrightness/display0"), &brightness.laptop, flags)
            || !bus.registerObject(QStringLiteral("/org/kde/ScreenBrightness/display1"), &brightness.external, flags)
            || !bus.registerService(QStringLiteral("org.kde.plasmashell"))
            || !bus.registerObject(QStringLiteral("/org/kde/osdService"), &osd, flags)) {
            qFatal("Could not register isolated brightness/OSD fixtures");
        }
    }
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        engine->rootContext()->setContextProperty(QStringLiteral("brightnessFixture"), &brightness);
        engine->rootContext()->setContextProperty(QStringLiteral("osdFixture"), &osd);
    }
private:
    BrightnessService brightness;
    OsdService osd;
};

QUICK_TEST_MAIN_WITH_SETUP(osd, Setup)
#include "runner.moc"
