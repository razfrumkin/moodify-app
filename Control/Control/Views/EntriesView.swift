//
//  EntriesView.swift
//  Control
//
//  Created by Raz Frumkin on 05/10/2022.
//

import SwiftUI
import CoreData

// renders an undetailed entry
struct EntryView: View {
    @Environment(\.managedObjectContext) private var context
    
    let entry: Entry
        
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 5)
            VStack(alignment: .leading) {
                let icon = Utilities.moodToIcon(mood: Int(entry.mood))
                let color = Utilities.moodToColor(mood: Int(entry.mood))
                let header = Utilities.moodToHeader(mood: Int(entry.mood))
                let dateTimeString = Utilities.formattedDateTime(from: entry.date)
                
                HStack() {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(color)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text(header)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.black)
                        Text("\(dateTimeString.0) • \(dateTimeString.1)")
                            .font(.caption).foregroundColor(.gray)
                    }
                }
                
                if entry.note != nil {
                    Text(entry.note!)
                        .lineLimit(1)
                        .foregroundColor(.gray)
                }
                
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
                    
                    let activitiesNotShownInPreviewCount = entry.activities!.count - Utilities.maximumPreviewActivities
                    
                    if activitiesNotShownInPreviewCount > 0 {
                        Text("And \(activitiesNotShownInPreviewCount) more")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .cornerRadius(20)
        }
    }
    
    // a function that returns a glimpse of activities from the current entry
    func getFirstActivities() -> [Activity] {
        var activities: [Activity] = []
        var index = 0
        for activity in entry.activities! {
            if index == Utilities.maximumPreviewActivities {
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
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    
    @State private var isNewEntryViewActive: Bool = false
    @State private var showDetailedEntryView: Bool = false
    @State private var showDeleteEntryDialog: Bool = false
    @State private var selectedEntry: Entry?
    
    var body: some View {
        VStack {
            Button("(DEBUGGING) Reset Entries (\(entries.count) entrie(s))") {
                for entry in entries {
                    context.delete(entry)
                }
                try? context.save()
            }
            Button("(DEBBUGING) Generate Entries (\(entries.count) entrie(s))") {
                let quotes = try? context.fetch(Quote.fetchRequest())
                let activities = try? context.fetch(Activity.fetchRequest())
                
                for index in 1...100 {
                    if index == 50 { continue } // debugging
                    let entry = Entry(context: context)
                    entry.quote = quotes!.randomElement()!
                    entry.mood = .random(in: 0...99)
                    for activity in activities! {
                        if Bool.random() { continue }
                        entry.addToActivities(activity)
                        try? context.save()
                    }
                    entry.note = "an dij nk cj fwkj en fe \nwnf uwn uwen uew fnuwef \nnfuwenu ewnun weufn ifnwi idjnsid k kwn dihn ishwi eubihds ij didsj nisj ne"
                    entry.isProductive = .random()
                    entry.date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1 - index, to: .now)!)
                    try? context.save()
                }
            }
            if entries.count > 0 {
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
                    .onDelete { indexSet in
                        for index in indexSet {
                            selectedEntry = entries[index]
                            showDeleteEntryDialog = true
                        }
                    }
                }
                .listStyle(.plain)
                .padding()
            } else {
                VStack {
                    Spacer()
                    Text("No entries yet...")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(.bar)
        .sheet(isPresented: $showDetailedEntryView) {
            DetailedEntryView(entry: $selectedEntry)
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
    }
}

struct EntriesView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        EntriesView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
