//
//  SettingsView.swift
//  Control
//
//  Created by Raz Frumkin on 05/10/2022.
//

import SwiftUI

// manage most of the settings and configurations of the application.
struct SettingsView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var entries: FetchedResults<Entry>
    @FetchRequest(sortDescriptors: []) private var activities: FetchedResults<Activity>
    
    @State private var showDeleteEntriesAlert: Bool = false
    @State private var showResetActivitiesAlert: Bool = false
    
    @AppStorage("reminder") private var reminder: Date = Utilities.getDefaultReminder()
    @AppStorage("weekStartsOnSunday") private var weekStartsOnSunday: Bool = true
        
    var body: some View {
        NavigationView {
            Form {
                Section("App Data") {
                    Button("Delete Entries Data", role: .destructive) {
                        showDeleteEntriesAlert = true
                    }
                    Button("Reset Activities Data", role: .destructive) {
                        showResetActivitiesAlert = true
                    }
                }
                
                Section("Time") {
                    DatePicker("Remind At", selection: $reminder, displayedComponents: .hourAndMinute)
                        .environment(\.locale, Locale(identifier: Utilities.localeIdentifier))
                        .onChange(of: reminder) { value in
                            NotificationManager.shared.cancelAllNotifications()
                            NotificationManager.shared.scheduleNotification(time: value)
                        }
                    
                    Picker("Week Starts On", selection: $weekStartsOnSunday) {
                        Text("Sunday")
                            .tag(true)
                        Text("Monday")
                            .tag(false)
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .tint(.pink)
        .navigationTitle("Settings")
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
                
                Utilities.prepopulateActivites(context: context)
            }
            Button("Cancel", role: .cancel) {
                
            }
        }, message: {
            Text("Are you sure you want to reset your activites? This action will delete all of your activities from every entry and you cannot undo this.")
        })
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        SettingsView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
