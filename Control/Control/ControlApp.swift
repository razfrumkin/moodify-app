//
//  ControlApp.swift
//  Control
//
//  Created by Raz Frumkin on 25/09/2022.
//

import SwiftUI
import CoreData

// a class that manages notifications
class NotificationManager {
    static let shared: NotificationManager = NotificationManager()
    
    // this function requests authorization from the user
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { success, error in
            if let error = error {
                fatalError("Unresolved User Notification error: \(error)")
            } else {
                NotificationManager.shared.cancelAllNotifications() // just incase
                NotificationManager.shared.scheduleNotification(time: Utilities.getDefaultReminder())
            }
        }
    }
    
    // this function schedules a notification
    func scheduleNotification(time: Date) {
        let remindMeIn1MinuteAction = UNNotificationAction(identifier: "reminderNotification.in1Minute", title: "Remind Me In 1 Minute", options: [])
        let remindMeIn10MinutesAction = UNNotificationAction(identifier: "reminderNotification.in10Minutes", title: "Remind Me In 10 Minutes", options: [])
        let remindMeIn30MinutesAction = UNNotificationAction(identifier: "reminderNotification.in30Minutes", title: "Remind Me In 30 Minutes", options: [])
        let remindMeIn1HourAction = UNNotificationAction(identifier: "reminderNotification.in1Hour", title: "Remind Me In 1 Hour", options: [])
        
        let reminderNotificationCategory = UNNotificationCategory(identifier: Utilities.reminderNotificationCategory, actions: [remindMeIn1MinuteAction, remindMeIn10MinutesAction, remindMeIn30MinutesAction, remindMeIn1HourAction], intentIdentifiers: [], options: .customDismissAction)
        
        UNUserNotificationCenter.current().setNotificationCategories([reminderNotificationCategory])
        
        let content = UNMutableNotificationContent()
        content.title = "How are you today?"
        content.subtitle = "Hop on to fill your entry!"
        content.sound = .default
        content.categoryIdentifier = Utilities.reminderNotificationCategory
        
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Utilities.reminderNotificationCategory])
    }
}

// manage and receive low level calls from the device and application
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // this function gets called when the application launches
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        Utilities.prepopulateData(context: PersistenceController.shared.container.viewContext)
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return true
    }
    
    // this function gets called when the application launches due to a notification tap or options
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
                
        let category = response.notification.request.content.categoryIdentifier
        
        switch category {
        case Utilities.reminderNotificationCategory:
            let action = response.actionIdentifier
            switch action {
            case "reminderNotification.in1Minute":
                NotificationManager.shared.scheduleTemporaryNotification(response: response, minutes: 1)
            case "reminderNotification.in10Minutes":
                NotificationManager.shared.scheduleTemporaryNotification(response: response, minutes: 10)
                break
            case "reminderNotification.in30Minutes":
                NotificationManager.shared.scheduleTemporaryNotification(response: response, minutes: 30)
                break
            case "reminderNotification.in1Hour":
                NotificationManager.shared.scheduleTemporaryNotification(response: response, minutes: 60)
                break
            default:
                // redirect to NewEntryView through HomeView
                ExternalData.shared.launchedViaEntryReminderNotification = true
                
                //fatalError("Unresolved User Notification error: Could not find the notification action: \"\(action)\"")
            }
            
            break
        default:
            fatalError("Unresolved User Notification error: Could not find the notification category: \"\(category)\"")
        }
        
        completionHandler()
    }
}

// this is used to pass data from AppDelegate to ContentView
struct ExternalData {
    static var shared: ExternalData = ExternalData()
    
    var launchedViaEntryReminderNotification: Bool = false
}

// load the persistence container from CoreData
struct PersistenceController {
    static let shared: PersistenceController = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "Database")
        
        container.loadPersistentStores { description, error in if let error = error as NSError? {
            fatalError("Unresolved CoreData error: \(error)")
        }}
    }
}

// the main struct of the application
@main
struct ControlApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        let persistenceContainer = PersistenceController.shared
                        
        WindowGroup {
            ContentView(viewRouter: ViewRouter())
                .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
        }
    }
}
