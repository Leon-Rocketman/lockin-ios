import Foundation
import UserNotifications

struct NotificationScheduler {
    private let alarmIdentifiers = (0..<5).map { "alarm_\($0)" }

    func scheduleAlarmSeries(date: Date) {
        let center = UNUserNotificationCenter.current()

        for i in 0..<5 {
            let content = UNMutableNotificationContent()
            content.title = "起床时间到了"
            content.body = "点击进入完成起床确认"
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.caf"))
            content.userInfo = ["route": "wakeflow"]

            let triggerDate = date.addingTimeInterval(Double(i) * 40)

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: triggerDate
                ),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: alarmIdentifiers[i],
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    func cancelAlarmSeries() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: alarmIdentifiers)
        center.removeDeliveredNotifications(withIdentifiers: alarmIdentifiers)
    }
}
