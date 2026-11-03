// SPDX-License-Identifier: GPL-3.0-only
#include <CalendarEvents/CalendarEventsPlugin>
#include <QTimer>
class Fixture final : public CalendarEvents::CalendarEventsPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.kde.CalendarEventsPlugin" FILE "fixture.json")
    Q_INTERFACES(CalendarEvents::CalendarEventsPlugin)
public:
    void loadEventsForDateRange(const QDate &start, const QDate &end) override {
        QMultiHash<QDate, CalendarEvents::EventData> result;
        for (QDate day = start; day <= end; day = day.addDays(1)) {
            CalendarEvents::EventData event;
            event.setUid(day.toString(Qt::ISODate));
            event.setTitle("Native event " + day.toString(Qt::ISODate));
            event.setStartDateTime(QDateTime(day, QTime(14, 0)));
            event.setEndDateTime(QDateTime(day, QTime(15, 0)));
            event.setEventType(CalendarEvents::EventData::Event);
            event.setEventColor("#c4b5fd");
            result.insert(day, event);
        }
        QTimer::singleShot(20, this, [this, result] { Q_EMIT dataReady(result); });
    }
};
#include "fixture.moc"
