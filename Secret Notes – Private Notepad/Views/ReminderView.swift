import SwiftUI
import UserNotifications

struct ReminderPickerView: View {
    @Binding var reminderTime: Date?
    @State private var isEnabled: Bool
    @State private var selectedDate: Date

    init(reminderTime: Binding<Date?>) {
        self._reminderTime = reminderTime
        self._isEnabled = State(initialValue: reminderTime.wrappedValue != nil)
        self._selectedDate = State(initialValue: reminderTime.wrappedValue ?? Date().addingTimeInterval(3600))
    }

    var body: some View {
        Toggle("Reminder", isOn: $isEnabled)
            .onChange(of: isEnabled) { _, enabled in
                if enabled {
                    reminderTime = selectedDate
                    requestNotificationPermission()
                } else {
                    reminderTime = nil
                }
            }

        if isEnabled {
            DatePicker(
                "Time",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .onChange(of: selectedDate) { _, newDate in
                reminderTime = newDate
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

struct ReminderScheduler {
    static func schedule(for note: SecretNote) {
        guard let reminderTime = note.reminderTime else { return }
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = note.title
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: note.syncId.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(for note: SecretNote) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [note.syncId.uuidString])
    }
}
