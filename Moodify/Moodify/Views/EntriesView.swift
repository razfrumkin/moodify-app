//
//  EntriesView.swift
//  Moodify
//
//  Created by Raz Frumkin on 05/10/2022.
//

import SwiftUI
import CoreData

// renders an undetailed entry
struct EntryView: View {
    @Environment(\.managedObjectContext) private var context // database instance
    
    private let maximumPreviewActivities: Int = 3 // preview activities are the little boxes that show which activities have been done in the entry, there can only be a maximum amount to preview

    let entry: Entry
        
    var body: some View {
        VStack(alignment: .leading) {
            let dateTimeString = Time.shared.formattedDateTime(from: entry.date)
            
            HStack() {
                Image(entry.icon)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(entry.color)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    Text(entry.header)
                        .font(.title2)
                        .bold()
                    Text("\(dateTimeString.0) • \(dateTimeString.1)")
                        .font(.caption).foregroundColor(.gray)
                }
            }
            
            // display the note if it exists
            if entry.note != nil {
                Text(entry.note!)
                    .lineLimit(1)
                    .foregroundColor(.gray)
            }
                
            // display a list of activities only if there is at least one activity
            if entry.activities != nil {
                let activities = getFirstActivities()
                
                HStack {
                    ForEach(activities) { activity in
                        HStack {
                            Image(systemName: activity.systemName ?? "x.circle.fill")
                            Text(activity.title ?? "REMOVED")
                        }
                        .font(.caption2)
                        .padding(5)
                        .foregroundColor(.gray)
                        .background(.bar)
                        .cornerRadius(10)
                    }
                }
                    
                let activitiesNotShownInPreviewCount = entry.activities!.count - maximumPreviewActivities
                
                if activitiesNotShownInPreviewCount > 0 {
                    Text("And \(activitiesNotShownInPreviewCount) more")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color.theme.secondaryBackground)
            .shadow(color: .theme.inverseBackground.opacity(0.1), radius: 10, y: 5))
    }
    
    // a function that returns a glimpse (preview) of activities from the current entry (based on the maximum to preview)
    func getFirstActivities() -> [Activity] {
        var activities: [Activity] = []
        var index = 0
        for activity in entry.activities! {
            if index == maximumPreviewActivities {
                return activities
            }
            
            activities.append(activity as! Activity)
            index += 1
        }
        
        return activities
    }
}

// renders all the entries of the application
struct EntriesView: View {
    @Environment(\.managedObjectContext) private var context // database instance
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry> // load entries data for the database and sort them by their dates
    
    @State private var showDetailedEntryView: Bool = false
    @State private var showDeleteEntryDialog: Bool = false
    @State private var selectedEntry: Entry?
    
    var body: some View {
        VStack {
            if !entries.isEmpty {
                List {
                    ForEach(entries) { entry in
                        EntryView(entry: entry)
                            .environment(\.managedObjectContext, context)
                            .onTapGesture {
                                selectedEntry = entry
                                showDetailedEntryView = true
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.black.opacity(0))
                            .padding(.vertical, 10)
                    }
                    .onDelete { indexSet in // swipe gesture to delete the entry (request deletion)
                        for index in indexSet {
                            selectedEntry = entries[index]
                            showDeleteEntryDialog = true
                        }
                    }
                }
                .listStyle(.plain)
                .padding()
            } else {
                NoDataView(message: "No entries yet...", detail: "Tap the Check-In button in the Home view to create a new entry.")
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .background(Color.theme.background)
        .sheet(isPresented: $showDetailedEntryView) {
            DetailedEntryView(entry: $selectedEntry)
                .environment(\.managedObjectContext, context)
                .presentationDetents([.large, .fraction(0.75)])
        }
        .alert("Delete Entry", isPresented: $showDeleteEntryDialog, actions: {
            Button("Delete", role: .destructive) {
                withAnimation {
                    context.delete(selectedEntry!)
                    
                    do {
                        try context.save()
                    } catch {
                        fatalError("Unresolved CoreData error: Could not delete the entry")
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                
            }
        }, message: {
            Text("Are you sure you want to delete this entry? You cannot undo this action.")
        })
        .navigationTitle("Entries")
    }
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct EntriesView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        EntriesView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
