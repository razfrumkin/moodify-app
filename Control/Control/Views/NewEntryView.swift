//
//  NewEntryView.swift
//  Control
//
//  Created by Raz Frumkin on 01/11/2022.
//

import SwiftUI

// view that allows the user to create a new entry
struct NewEntryView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var quotes: FetchedResults<Quote>
    @FetchRequest(sortDescriptors: []) private var activities: FetchedResults<Activity>
            
    @State private var selectedActivities: [Activity] = []
    
    @Binding var isActive: Bool
        
    @State private var showSelectQuote: Bool = false
    @State private var showNewActivityView: Bool = false
    @State private var showModifyActivityDialog: Bool = false
    @State private var showRenameActivityAlert: Bool = false
    @State private var showDeleteActivityAlert: Bool = false
    
    @State private var selectedActivityToModify: Activity?
    @State private var newPossibleActivityTitle: String = ""
    
    @State private var selectedQuote: Quote?
    @State private var mood: Double = Entry.maximumMood / 2.0
    @State private var note: String = ""
    @State private var isProductive: Bool = false
        
    var body: some View {
        ScrollView {
            Button("Reset Activities (\(activities.count) activitie(s))") {
                for activity in activities {
                    context.delete(activity)
                }
                try? context.save()
                context.prepopulateActivites()
            }
            ZStack {
                Rectangle()
                    .fill(.linearGradient(colors: Utilities.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 400)
                Button(action: {
                    showSelectQuote = true
                }, label: {
                    if selectedQuote == nil {
                        Text("Tap to add a quote")
                            .foregroundColor(.white)
                            .font(.title)
                    } else {
                        VStack(alignment: .leading) {
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\"\(selectedQuote!.content ?? "Unresolved quote")\"")
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.title.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                                Text("- \(selectedQuote!.author ?? "Unknown")")
                                    .foregroundColor(.white.opacity(0.6))
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
                                    .foregroundColor(.white)
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
                            .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)
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
                            .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)
                        Spacer()
                        Button(action: {
                            showNewActivityView = true
                        }, label: {
                            Image(systemName: "plus")
                                .frame(width: 30, height: 30)
                                .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)                                .cornerRadius(15)
                                .padding(.leading)
                                .font(.title3)
                        })
                    }
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
                
                Group {
                    Label("Add a daily note", systemImage: "square.text.square.fill")
                        .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)
                    TextField("Type your note here...", text: $note, axis: .vertical)
                        .font(.body)
                        .padding()
                        .background(.bar)
                        .cornerRadius(10)
                        .lineLimit(5)
                }
                
                Group {
                    HStack {
                        Label("Was this day productive?", systemImage: "bolt.fill")
                            .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isProductive)
                            .toggleStyle(.switch)
                            .fixedSize()
                            .tint(.accentColor)
                    }
                }
            }
            .padding()
            
            Button("Save") {
                saveEntry()
                isActive = false
            }
            .padding()
            .foregroundColor(.white)
            .frame(width: 200, height: 50)
            .background(.linearGradient(colors: Utilities.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
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
            NewActivityView(isActive: $showNewActivityView)
        }
        .alert("Rename Activity", isPresented: $showRenameActivityAlert) {
            TextField("Activity title here...", text: $newPossibleActivityTitle)
            
            Button("Proceed") {
                selectedActivityToModify!.title = newPossibleActivityTitle
                                                    
                do {
                    try context.save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not rename the activity's title")
                }
                
                newPossibleActivityTitle = ""
            }
            Button("Cancel", role: .cancel) {
                newPossibleActivityTitle = ""
            }
        }
        .alert("Delete Activity", isPresented: $showDeleteActivityAlert, actions: {
            Button("Delete", role: .destructive) {
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
        .onAppear {
            selectedQuote = nil
            mood = 0
            note = ""
            isProductive = false
        }
    }
    
    // this function creates a new entry in the database
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
        
        if !note.isEmpty {
            entry.note = note
        }
        
        entry.isProductive = isProductive
        
        do {
            try context.save()
        } catch {
            fatalError("Unresolved CoreData error: Could not save entry data")
        }
    }
}

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        NewEntryView(viewRouter: ViewRouter(), isActive: .constant(true))
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
