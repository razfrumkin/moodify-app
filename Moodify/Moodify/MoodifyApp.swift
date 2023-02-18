//
//  MoodifyApp.swift
//  Moodify
//
//  Created by Raz Frumkin on 25/09/2022.
//

import SwiftUI
import CoreData

// manage and receive low level calls from the device and application
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // this function gets called when the application launches
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // set notification center delegate to this delegate
        UNUserNotificationCenter.current().delegate = self
        
        // preload app data
        preload()
        
        // set notification badge number to zero because the app has launched
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return true // success
    }
    
    // this function gets called when the application launches due to a notification tap or notification options tab
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // get notification category
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
            default: // if none of the actions match, then the user tapped the notification instead of tapping one of its actions
                // redirect to NewEntryView through HomeView
                ExternalData.shared.launchedViaEntryReminderNotification = true
            }
            
            break
        default:
            fatalError("Unresolved User Notification error: Could not find the notification category: \"\(category)\"")
        }
        
        completionHandler() // should be called according to Apple
    }
    
    // preload all the default data
    private func preload() {
        // this condition is true if the application got launched for the first time
        if UserDefaults.standard.object(forKey: "firstLaunch") == nil {
            UserDefaults.standard.set(true, forKey: "firstLaunch") // create "firstLaunch" key
            UserDefaults.standard.set(SchemeType.light.rawValue, forKey: "schemeType") // set color theme to light by default
            UserDefaults.standard.set(NotificationManager.shared.getDefaultReminder(), forKey: "reminder") // set the reminder notification to its default value
            
            // prepopulate default data
            context.prepopulateQuotes()
            context.prepopulateActivites()
            context.prepopulateDailyChallenges()
        }
    }
    
    // get database instance
    var context: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
}

// this struct is used to pass data from AppDelegate to ContentView
struct ExternalData {
    static var shared: ExternalData = ExternalData()
    
    // tells the app whether it got launched via a notification tap (specifically the reminder notification)
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
struct MoodifyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        let persistenceContainer = PersistenceController.shared
                        
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
        }
    }
}
