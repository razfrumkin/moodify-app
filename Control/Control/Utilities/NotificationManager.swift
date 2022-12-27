//
//  NotificationManager.swift
//  Control
//
//  Created by Raz Frumkin on 27/12/2022.
//

import Foundation
import UserNotifications

// a class that manages notifications
class NotificationManager {
    static let shared: NotificationManager = NotificationManager()
    
    let reminderNotificationCategoryIdentifier: String = "reminderNotification"
    
    // this function requests authorization from the user
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { success, error in
            if let error = error {
                fatalError("Unresolved User Notification error: \(error)")
            } else {
                NotificationManager.shared.cancelAllNotifications()
                NotificationManager.shared.scheduleNotification(time: NotificationManager.shared.getDefaultReminder())
            }
        }
    }
    
    // this function schedules a notification
    func scheduleNotification(time: Date) {
        let remindMeIn1MinuteAction = UNNotificationAction(identifier: "reminderNotification.in1Minute", title: "Remind Me In 1 Minute", options: [])
        let remindMeIn10MinutesAction = UNNotificationAction(identifier: "reminderNotification.in10Minutes", title: "Remind Me In 10 Minutes", options: [])
        let remindMeIn30MinutesAction = UNNotificationAction(identifier: "reminderNotification.in30Minutes", title: "Remind Me In 30 Minutes", options: [])
        let remindMeIn1HourAction = UNNotificationAction(identifier: "reminderNotification.in1Hour", title: "Remind Me In 1 Hour", options: [])
        
        let reminderNotificationCategory = UNNotificationCategory(identifier: reminderNotificationCategoryIdentifier, actions: [remindMeIn1MinuteAction, remindMeIn10MinutesAction, remindMeIn30MinutesAction, remindMeIn1HourAction], intentIdentifiers: [], options: .customDismissAction)
        
        UNUserNotificationCenter.current().setNotificationCategories([reminderNotificationCategory])
        
        let content = UNMutableNotificationContent()
        content.title = "How are you today?"
        content.subtitle = "Hop on to fill your entry!"
        content.sound = .default
        content.categoryIdentifier = reminderNotificationCategoryIdentifier
        
        var dateComponents = DateComponents()
        dateComponents.hour = Calendar.current.component(.hour, from: time)
        dateComponents.minute = Calendar.current.component(.minute, from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                fatalError("Unresolved User Notification error: \(error)")
            }
        }
    }
    
    // this function takes a notification and snoozes it by a given number of minutes
    func scheduleTemporaryNotification(response: UNNotificationResponse, minutes: Int) {
        let newContent = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
        
        let newTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: newContent, trigger: newTrigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                fatalError("Unresolved User Notification error: \(error)")
            }
        }
    }
    
    // this function cancels ALL notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderNotificationCategoryIdentifier])
    }
    
    // returns the default reminder time incase the user hasn't set time for the daily notification
    func getDefaultReminder() -> Date {
        return Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: .now)!
    }
}
