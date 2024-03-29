//
//  NewEntryView.swift
//  Moodify
//
//  Created by Raz Frumkin on 01/11/2022.
//

import SwiftUI

// view that allows the user to create a new entry
struct NewEntryView: View {    
    @Environment(\.dismiss) private var dismiss // manual dismiss
    @Environment(\.managedObjectContext) private var context // context instance
    @FetchRequest(sortDescriptors: []) private var quotes: FetchedResults<Quote> // quotes data
    @FetchRequest(sortDescriptors: []) private var activities: FetchedResults<Activity> // activities data
            
    @State private var selectedActivities: [Activity] = []
            
    @State private var showSelectQuote: Bool = false
    @State private var showNewActivityView: Bool = false
    @State private var showModifyActivityDialog: Bool = false
    @State private var showRenameActivityAlert: Bool = false
    @State private var showDeleteActivityAlert: Bool = false
    @State private var invalidActivityTitle: Bool = false
    
    @State private var selectedActivityToModify: Activity?
    @State private var newPossibleActivityTitle: String = ""
    
    @State private var selectedQuote: Quote?
    @State private var mood: Double = Entry.maximumMood / 2.0
    @State private var note: String = ""
        
    var body: some View {
        ScrollView {
            ZStack {
                Rectangle()
                    .fill(Color.theme.color)
                    .frame(height: 400)
                Button(action: {
                    showSelectQuote = true
                }, label: {
                    if selectedQuote == nil {
                        Text("Tap to add a quote")
                            .foregroundColor(.theme.background)
                            .font(.title)
                    } else {
                        VStack(alignment: .leading) {
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\"\(selectedQuote!.content ?? "Unresolved quote")\"")
                                    .foregroundColor(.theme.background.opacity(0.9))
                                    .font(.title.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                                Text("- \(selectedQuote!.author ?? "Unknown")")
                                    .foregroundColor(.theme.background.opacity(0.6))
                                    .font(.body.italic().bold())
                                    .multilineTextAlignment(.leading)                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    selectedQuote = nil
                                }
                            }, label: {
                                Label("No quote", systemImage: "rectangle.badge.minus")
                                    .foregroundColor(.theme.background)
                            })
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                })
            }
            
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    HStack {
                        Label("Add your mood", systemImage: "face.smiling")
                            .foregroundColor(.theme.color)
                        Spacer()
                        
                        Image(Entry.moodToIcon(mood: Int(mood)))
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Entry.moodToColor(mood: Int(mood)))
                            .frame(width: 20, height: 20)
                    }
                    Slider(value: $mood, in: 0...Entry.maximumMood, step: 1.0)
                        .tint(Entry.moodToColor(mood: Int(mood)))
                }
                
                Group {
                    HStack {
                        Label("Select your activites", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.theme.color)
                        Spacer()
                        Button(action: {
                            showNewActivityView = true
                        }, label: {
                            Image(systemName: "plus")
                                .frame(width: 30, height: 30)
                                .foregroundColor(.theme.color)
                                .padding(.leading)
                                .font(.title3)
                        })
                    }
                    
                    if activities.isEmpty {
                        Text("No activities... Tap the + to add an activity!")
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                            ForEach(activities) { activity in
                                ActivityView(activity: activity) { isSelected in
                                    if isSelected {
                                        selectedActivities.append(activity)
                                    } else {
                                        selectedActivities.remove(at: selectedActivities.firstIndex(of: activity)!)
                                    }
                                }
                                .simultaneousGesture(LongPressGesture().onEnded { _ in
                                    selectedActivityToModify = activity
                                    showModifyActivityDialog = true
                                })
                            }
                            .confirmationDialog("", isPresented: $showModifyActivityDialog) {
                                Button("Rename") {
                                    newPossibleActivityTitle = selectedActivityToModify!.title!
                                    showRenameActivityAlert = true
                                }
                                Button("Delete", role: .destructive) {
                                    showDeleteActivityAlert = true
                                }
                            }
                        }
                    }
                }
                
                Group {
                    Label("Add a daily note", systemImage: "square.text.square.fill")
                        .foregroundColor(.theme.color)
                    TextField("Type your note here...", text: $note, axis: .vertical)
                        .font(.body)
                        .padding()
                        .background(.bar)
                        .cornerRadius(10)
                        .lineLimit(5)
                }
            }
            .padding()
            
            Button("Save") {
                saveEntry()
                dismiss()
            }
            .padding()
            .foregroundColor(.white)
            .frame(width: 200, height: 50)
            .background(Color.theme.color)
            .cornerRadius(10)
        }
        .sheet(isPresented: $showSelectQuote) {
            VStack {
                if quotes.atLeastOneLikedQuote {
                    List {
                        ForEach(quotes) { quote in
                            if quote.isLiked {
                                Text("\"\(quote.content ?? "Unresolved quote")\"")
                                    .lineLimit(1)
                                    .onTapGesture {
                                        selectedQuote = quote
                                        showSelectQuote = false
                                    }
                            }
                        }
                    }
                } else {
                    Text("You haven't liked any quotes yet")
                }
            }
        }
        .sheet(isPresented: $showNewActivityView) {
            NewActivityView()
        }
        .alert("Rename Activity", isPresented: $showRenameActivityAlert) {
            TextField("Activity title here...", text: $newPossibleActivityTitle)
            
            Button("Proceed") {
                let trimmed = newPossibleActivityTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if trimmed.count >= Activity.minimumNameLength && trimmed.count <= Activity.maximumNameLength && !activities.titleExists(title: trimmed) {
                    selectedActivityToModify!.title = trimmed
                    
                    do {
                        try context.save()
                    } catch {
                        fatalError("Unresolved CoreData error: Could not rename the activity's title")
                    }
                    
                    newPossibleActivityTitle = ""
                } else {
                    invalidActivityTitle = true
                }
            }
            Button("Cancel", role: .cancel) {
                newPossibleActivityTitle = ""
            }
        }
        .alert("Delete Activity", isPresented: $showDeleteActivityAlert, actions: {
            Button("Delete", role: .destructive) {
                if let index = selectedActivities.firstIndex(of: selectedActivityToModify!) {
                    selectedActivities.remove(at: index)
                }
                
                context.delete(selectedActivityToModify!)
                
                do {
                    try context.save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not delete the activity")
                }
            }
            Button("Cancel", role: .cancel) {
                
            }
        }, message: {
            Text("Are you sure you want to delete this activity? Deleting this activity will delete every instance of this activity from every entry.")
        })
        .alert("Invalid Title", isPresented: $invalidActivityTitle, actions: {
            Button("Cancel", role: .cancel) {
                
            }
        }, message: {
                Text("Activity title must be within \(Activity.minimumNameLength) to \(Activity.maximumNameLength) characters and cannot match an existing activity title.")
        })
        .onAppear {
            selectedQuote = nil
            mood = 0
            note = ""
        }
        .navigationTitle("New Entry")
    }
    
    // this function inserts a new entry in the database
    private func saveEntry() {
        let entry = Entry(context: context)
        
        entry.date = .now
        entry.quote = selectedQuote
        entry.mood = Int16(mood)
        
        for selectedActivity in selectedActivities {
            entry.addToActivities(selectedActivity)
            do {
                try context.save()
            } catch {
                fatalError("Unresolved CoreData error: Could not add activities")
            }
        }
        
        // if the note is empty then keep it nil so it saves allocation space
        if !note.isEmpty {
            entry.note = note
        }
                
        do {
            try context.save()
        } catch {
            fatalError("Unresolved CoreData error: Could not save entry data")
        }
    }
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        NewEntryView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
