//
//  ControlApp.swift
//  Control
//
//  Created by Raz Frumkin on 25/09/2022.
//

import SwiftUI
import CoreData

// manage and receive low level calls from the device and application
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // this function gets called when the application launches
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        preload()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return true
    }
    
    // this function gets called when the application launches due to a notification tap or options
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
                
        let category = response.notification.request.content.categoryIdentifier
        
        switch category {
        case NotificationManager.shared.reminderNotificationCategoryIdentifier:
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
            }
            
            break
        default:
            fatalError("Unresolved User Notification error: Could not find the notification category: \"\(category)\"")
        }
        
        completionHandler()
    }
    
    // preload all the default data
    private func preload() {
        if UserDefaults.standard.object(forKey: "firstLaunch") == nil {
            UserDefaults.standard.set(true, forKey: "firstLaunch")
            UserDefaults.standard.set(SchemeType.light.rawValue, forKey: "schemeType")
            UserDefaults.standard.set(NotificationManager.shared.getDefaultReminder(), forKey: "reminder")
            UserDefaults.standard.set(true, forKey: "weekStartsOnSunday")
            context.prepopulateQuotes()
            context.prepopulateActivites()
            context.prepopulateDailyChallenges()
        }
    }
    
    var context: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
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
