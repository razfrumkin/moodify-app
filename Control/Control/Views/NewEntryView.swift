//
//  NewEntryView.swift
//  Control
//
//  Created by Raz Frumkin on 01/11/2022.
//

import SwiftUI

struct NewEntryView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var quotes: FetchedResults<Quote>
    @FetchRequest(sortDescriptors: []) private var activities: FetchedResults<Activity>
        
    @State private var selectedActivities: [Activity] = []
    
    @Binding public var isActive: Bool
    
    @State private var showSelectQuote: Bool = false
    
    @State private var selectedQuote: Quote?
    @State private var mood: Double = 0.0
    @State private var note: String = ""
    @State private var isProductive: Bool = false
        
    var body: some View {
        ScrollView {
            Button("Reset Activities (\(activities.count) activitie(s))") {
                for activity in activities {
                    context.delete(activity)
                }
                try? context.save()
                prepopulateActivites(context: context)
            }
            ZStack {
                Rectangle()
                    .fill(.purple)
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
                                    .font(.title.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                Text("- \(selectedQuote!.author ?? "Unknown")")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.body.italic().bold())
                                    .multilineTextAlignment(.leading)
                            }
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
                        .padding()
                    }
                })
            }
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    HStack {
                        Label("Add your mood", systemImage: "face.smiling.fill")
                            .foregroundColor(.pink)

                        Text(String(Utilities.moodToEmoji(mood: Int(mood))))
                    }
                    Slider(value: $mood, in: 0...Utilities.maximumMood, step: 1.0)
                        .accentColor(.purple)
                }
                
                Group {
                    Label("Select your activites", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.pink)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                        ForEach(activities) { activity in
                            ActivityView(activity: activity) { isSelected in
                                if isSelected {
                                    selectedActivities.append(activity)
                                } else {
                                    selectedActivities.remove(at: selectedActivities.firstIndex(of: activity)!)
                                }
                            }
                        }
                    }
                }
                
                Group {
                    Label("Add a daily note", systemImage: "square.text.square.fill")
                        .foregroundColor(.pink)
                    TextField("Type your note here...", text: $note, axis: .vertical)
                        .font(.body)
                        .accentColor(.pink)
                        .padding()
                        .background(.bar)
                        .cornerRadius(10)
                        .lineLimit(5)
                }
                
                Group {
                    Toggle("Was this day productive?", isOn: $isProductive)
                        .toggleStyle(.switch)
                        .foregroundColor(.pink)
                        .tint(.purple)
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
            .background(.purple)
            .cornerRadius(10)
        }
        .navigationTitle("New Entry")
        .sheet(isPresented: $showSelectQuote) {
            VStack {
                if atLeastOneLikedQuote() {
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
        .onAppear {            
            selectedQuote = nil
            mood = 0
            note = ""
            isProductive = false
        }
    }
    
    private func saveEntry() {
        let entry = Entry(context: context)
        
        entry.date = .now
        entry.quote = selectedQuote
        entry.mood = Int16(mood)
        
        for selectedActivity in selectedActivities {
            entry.addToActivities(selectedActivity)
        }
        
        if note.isEmpty {
            entry.note = note
        }
        entry.isProductive = isProductive
        
        do {
            try context.save()
        } catch {
            fatalError("Unresolved CoreData error: Could not save entry data")
        }
    }
    
    private func atLeastOneLikedQuote() -> Bool {
        for quote in quotes {
            if quote.isLiked {
                return true
            }
        }
        return false
    }
}

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        NewEntryView(isActive: .constant(true))
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
