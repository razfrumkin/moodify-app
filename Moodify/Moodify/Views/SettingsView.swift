//
//  SettingsView.swift
//  Moodify
//
//  Created by Raz Frumkin on 05/10/2022.
//

import SwiftUI

// manage most of the settings and configurations of the application.
struct SettingsView: View {    
    @Environment(\.managedObjectContext) private var context // database instance
    @FetchRequest(sortDescriptors: []) private var entries: FetchedResults<Entry> // entries data
    @FetchRequest(sortDescriptors: []) private var activities: FetchedResults<Activity> // activities data
    @FetchRequest(sortDescriptors: []) private var appearances: FetchedResults<DailyAppearance> // daily challenges data
    @FetchRequest(sortDescriptors: []) private var quotes: FetchedResults<Quote> // quotes data
    
    @State private var showDeleteEntriesAlert: Bool = false
    @State private var showResetActivitiesAlert: Bool = false
    @State private var showDeleteDailyChallengesAlert: Bool = false
    @State private var showResetQuotesAlert: Bool = false
    
    @AppStorage("schemeType") private var schemeType: SchemeType = .light // sync schemeType value from UserDefaults
    @AppStorage("reminder") private var reminder: Date = NotificationManager.shared.getDefaultReminder() // sync reminder value from UserDefaults
        
    var body: some View {
        Form {
            Section("App Data") {
                Button("Delete Entries Data", role: .destructive) {
                    showDeleteEntriesAlert = true
                }
                Button("Reset Activities Data", role: .destructive) {
                    showResetActivitiesAlert = true
                }
                Button("Delete Daily Challenges Data", role: .destructive) {
                    showDeleteDailyChallengesAlert = true
                }
                Button("Reset Quotes Data", role: .destructive) {
                    showResetQuotesAlert = true
                }
            }
            
            Section("Appearance") {
                Picker("Color Theme", selection: $schemeType) {
                    ForEach(SchemeType.allCases) { value in
                        Text(value.title)
                            .tag(value)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: schemeType) { value in
                    Visuals.shared.changeColorScheme(scheme: value.colorScheme)
                }
            }
            
            Section("Time") {
                DatePicker("Check-In Notification", selection: $reminder, displayedComponents: .hourAndMinute)
                    .environment(\.locale, Locale(identifier: Time.shared.localeIdentifier))
                    .onChange(of: reminder) { value in
                        NotificationManager.shared.cancelAllNotifications()
                        NotificationManager.shared.scheduleNotification(time: value)
                    }
            }
            
            Section("Debugging") {
                Button("Generate Entries (\(entries.count) entrie(s))") {
                    let quotes = try? context.fetch(Quote.fetchRequest())
                    let activities = try? context.fetch(Activity.fetchRequest())
                    
                    let letters = " abcd efghi jklmn opqr stuv wxyz "
                    
                    for index in 1...50 {
                        if Int.random(in: 0...4) == 4 { continue }
                        let entry = Entry(context: context)
                        entry.quote = quotes!.randomElement()!
                        entry.mood = .random(in: 0...99)
                        for activity in activities! {
                            if Bool.random() { continue }
                            entry.addToActivities(activity)
                            try? context.save()
                        }
                        let length = Int.random(in: 10...200)
                        var note = ""
                        for _ in 0..<length {
                            note += String(letters.randomElement()!)
                        }
                        entry.note = note
                        entry.date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1 - index, to: .now)!)
                        try? context.save()
                    }
                }
            }
        }
        .alert("Delete Entries Data", isPresented: $showDeleteEntriesAlert, actions: {
            Button("Delete", role: .destructive) {
                for entry in entries {
                    context.delete(entry)
                }
                
                do {
                    try context.save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not delete entries data")
                }
            }
            
            Button("Cancel", role: .cancel) {
                
            }
        }, message: {
            Text("Are you sure you want to delete all of your entries? You cannot undo this action.")
        })
        .alert("Reset Activities Data", isPresented: $showResetActivitiesAlert, actions: {
            Button("Delete", role: .destructive) {
                for activity in activities {
                    context.delete(activity)
                }
                
                do {
                    try context.save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not delete activities data")
                }
                
                context.prepopulateActivites()
            }
            
            Button("Cancel", role: .cancel) {
                
            }
        }, message: {
            Text("Are you sure you want to reset your activites? This action will delete all of your activities from every entry and you cannot undo this action.")
        })
        .alert("Reset Daily Challenges Data", isPresented: $showDeleteDailyChallengesAlert, actions: {
            Button("Delete", role: .destructive) {
                for appearance in appearances {
                    context.delete(appearance)
                }
                
                do {
                    try context.save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not delete appearances data")
                }
            }
            
            Button("Cancel", role: .cancel) {
                
            }
        }, message: {
            Text("Are you sure you want to delete all of your daily challenges? You cannot undo this action.")
        })
        .alert("Reset Quotes Data", isPresented: $showResetQuotesAlert, actions: {
            Button("Delete", role: .destructive) {
                for quote in quotes {
                    context.delete(quote)
                }
                
                do {
                    try context.save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not delete quotes data")
                }
                
                context.prepopulateQuotes()
            }
        }, message: {
            Text("Are you sure you want to delete all of the quotes data? You cannot undo this action.")
        })
    }
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        SettingsView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
