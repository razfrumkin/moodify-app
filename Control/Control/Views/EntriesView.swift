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
    
    private let maximumPreviewActivities: Int = 3

    let entry: Entry
        
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.theme.secondaryBackground)
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
                    
                    let activitiesNotShownInPreviewCount = entry.activities!.count - maximumPreviewActivities
                    
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
                
                let letters = " abcd efghi jklmn opqr stuv wxyz "
                
                for index in 1...400 {
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
    }
}

struct EntriesView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        EntriesView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
