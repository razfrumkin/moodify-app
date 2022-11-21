//
//  EntriesView.swift
//  Control
//
//  Created by Raz Frumkin on 05/10/2022.
//

import SwiftUI
import CoreData

struct EntryView: View {
    @Environment(\.managedObjectContext) private var context

    @State private var isDetailedEntryViewActive: Bool = false
    
    public var entry: Entry
    
    var body: some View {
        EmptyView()
        /*NavigationLink(destination: DetailedEntryView(entry: entry, isActive: $isDetailedEntryViewActive), isActive: $isDetailedEntryViewActive) {
            VStack {
                HStack {
                    let dateTimeString = formattedDateTime(from: entry.date)
                    Text(dateTimeString.0)
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    Text("\(entry.mood)%")
                        .bold()
                        .foregroundColor(.white)
                    Spacer()
                    Text(dateTimeString.1)
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.white)
                        .frame(width: 275, height: 15)
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.pink.opacity(0.5))
                        .frame(width: 275 * Double(entry.mood) / Utilities.maximumMood, height: 15)
                }
            }
            .padding()
            .background(.pink)
            .cornerRadius(20)
        }*/
    }
    
    func formattedDateTime(from: Date?) -> (String, String) {
        if from == nil {
            return ("Unresolved date", "Unresolved time")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: from!).uppercased()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        let timeString = formatter.string(from: from!)
        
        return (dateString, timeString)
    }
}

struct EntriesView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Reset Entries (\(entries.count) entrie(s))") {
                    for entry in entries {
                        context.delete(entry)
                    }
                    try? context.save()
                }
                
                if !entries.isEmpty {
                    ScrollView {
                        ForEach(entries) { entry in
                            EntryView(entry: entry)
                                .environment(\.managedObjectContext, context)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct EntriesView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        EntriesView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
