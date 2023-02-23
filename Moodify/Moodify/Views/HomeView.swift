//
//  HomeView.swift
//  Moodify
//
//  Created by Raz Frumkin on 04/10/2022.
//

import SwiftUI
import CoreData

// this view will open first when the app launches (unless opened via a notification tap)
struct HomeView: View {
    @StateObject var viewRouter: ViewRouter // view router instance
    
    @Environment(\.managedObjectContext) private var context // database instance
    @Environment(\.scenePhase) private var scenePhase // important to handle the timer countdown
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry> // load entries data for the database and sort them by their dates
    @FetchRequest(sortDescriptors: []) private var dailyChallenges: FetchedResults<DailyChallenge> // load all the possible daily challenges
    
    @AppStorage("dailyChallengeDate") var dailyChallengeDate: Date = Calendar.current.startOfDay(for: .now) // deadline of the daily challenge
    @AppStorage("dailyChallengeID") var dailyChallengeID: String = "" // daily challenge identifier of the current daily challenge
    
    @Namespace private var namespace // sync animations with the assistance view
    
    @State private var showAssistanceView: Bool = false
    @State private var isNewEntryViewActive: Bool = false
    @State private var isEntriesViewActive: Bool = false
    @State private var showNewActivityView: Bool = false
    @State private var showDailyChallenge: Bool = false

    @State private var timeRemaining: Int = 0 // time remaining until to load a new daily challenge (time until the end of the current day)
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // timer that ticks at the speed of a single tick per second
    @State private var isActive: Bool = true // flag that makes sure the timer would only run only if this current view (HomeView) is active

    private let cornerRadius: CGFloat = 25 // common corner radius for the elements in this view
    
    var body: some View {
        if showAssistanceView {
            AssistanceView(viewRouter: viewRouter, isActive: $showAssistanceView, namespace: namespace)
                .environment(\.managedObjectContext, context)
        } else {
            ZStack {
                VStack {
                    Circle()
                        .fill(Color.theme.color)
                        .frame(width: 700)
                        .offset(y: -475)
                    Spacer()
                }
                
                ScrollView {
                    VStack(spacing: 10) {
                        HStack {
                            let days = getDaysInARow()
                            Text("\(days) day\(days == 1 ? "" : "s") in a row")
                                .font(.title)
                                .fontWeight(.medium)
                                .bold()
                                .foregroundColor(.theme.background)
                                .padding()
                            Spacer()
                            Text("\(Time.shared.monthAndDay(from: .now).uppercased())")
                                .font(.headline)
                                .foregroundColor(.theme.background)
                                .padding()
                        }
                        
                        VStack {
                            HStack(spacing: 0) {
                                let dateComponents = Calendar(identifier: .gregorian).dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
                                let startOfWeek = Calendar(identifier: .gregorian).date(from: dateComponents)!
                                let startOfWeekNoon = Calendar(identifier: .gregorian).date(bySettingHour: 12, minute: 0, second: 0, of: startOfWeek)!
                                
                                // other option is monday
                                let offset = Time.shared.weekStartsOnSunday() ? 1 : 0
                                
                                ForEach(1...7, id: \.self) { day in
                                    let weekDay = Calendar(identifier: .gregorian).date(byAdding: .day, value: day - offset, to: startOfWeekNoon)!
                                    
                                    let isToday = Calendar.current.isDate(weekDay, equalTo: .now, toGranularity: .day)
                                    
                                    Spacer()
                                    VStack(spacing: 5) {
                                        Text(weekDay.formatted(Date.FormatStyle().locale(Locale(identifier: Time.shared.localeIdentifier)).weekday(.abbreviated)))
                                            .foregroundColor(.theme.inverseBackground)
                                            .font(.footnote)
                                        Text("\(Time.shared.getMonthDay(from: weekDay))")
                                            .foregroundColor(Color.theme.inverseBackground.opacity(0.5))
                                            .bold()
                                    }
                                    .padding(.all, 5)
                                    .background(isToday ? Color.theme.color.opacity(0.75) : .clear)
                                    .cornerRadius(10)
                                    Spacer()
                                }
                            }
                            .padding()
                        }
                        .frame(height: 150)
                        .background(RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.theme.secondaryBackground)
                            .shadow(color: .theme.inverseBackground.opacity(0.1), radius: 10, y: 5))
                        .padding()
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Options")
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            VStack {
                                Button(action: {
                                    showNewActivityView = true
                                }, label: {
                                    HStack {
                                        Image(systemName: "plus")
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Circle()
                                                .fill(Color.theme.color))
                                        
                                        VStack(spacing: 10) {
                                            HStack {
                                                Text("New Activity")
                                                InformationButton(title: "New Activity", message: "An activity is some data that represents some activity you have done throughout the day. You can create one using the \"New Activity\" button. You assign it a title, for example: \"Cooking\" and apply an icon to recognize it. One you've created the activity, you select it when creating an entry to let us know you've done this activity for a given day.")
                                                Spacer()
                                            }
                                            .foregroundColor(Color.theme.inverseBackground)

                                            HStack {
                                                Image(systemName: "hand.tap.fill")
                                                    .foregroundColor(.theme.color)
                                                Text("Add an activity")
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: cornerRadius)
                                        .fill(Color.theme.secondaryBackground)
                                        .shadow(color: .theme.inverseBackground.opacity(0.1), radius: 10, y: 5))
                                })
                                
                                NavigationLink(destination: EntriesView()
                                    .environment(\.managedObjectContext, context), isActive: $isEntriesViewActive) {
                                    HStack {
                                        Image(systemName: "list.bullet.rectangle")
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Circle()
                                                .fill(Color.theme.color))
                                        
                                        VStack(spacing: 10) {
                                            HStack {
                                                Text("Entries")
                                                InformationButton(title: "Entries", message: "Pressing the \"Entries\" button will navigate to your history of check-ins on this app.")
                                                Spacer()
                                            }
                                            .foregroundColor(Color.theme.inverseBackground)
                                            
                                            HStack {
                                                Image(systemName: "hourglass")
                                                    .foregroundColor(.theme.color)
                                                Text("Your entries history")
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: cornerRadius)
                                        .fill(Color.theme.secondaryBackground)
                                        .shadow(color: .theme.inverseBackground.opacity(0.1), radius: 10, y: 5))
                                }
                            }
                            .padding()
                        }
                        
                        VStack(spacing: 0) {
                            HStack {
                                Text("Routines")
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal) {
                                HStack {
                                    Button(action: {
                                        showDailyChallenge = true
                                    }, label: {
                                        let isCompleted = isDailyChallengeCompleted()
                                        VStack(spacing: 10) {
                                            Text("Daily challenge")
                                                .foregroundColor(isCompleted ? .theme.secondaryBackground : .theme.inverseBackground)
                                            if isCompleted {
                                                HStack {
                                                    Image(systemName: "checkmark.circle.fill")
                                                    Text("Completed")
                                                }
                                                .foregroundColor(.theme.secondaryBackground)
                                                .font(.callout)
                                            } else {
                                                HStack {
                                                    Image(systemName: "clock")
                                                        .foregroundColor(.theme.color)
                                                    Text("Ends in \(Time.shared.hoursMinutesSeconds(seconds: timeRemaining))")
                                                        .foregroundColor(.secondary)
                                                }
                                                .font(.caption)
                                            }
                                        }
                                        .frame(width: 150, height: 100)
                                        .background(RoundedRectangle(cornerRadius: cornerRadius)
                                            .fill(isCompleted ? Color.theme.color : Color.theme.secondaryBackground)
                                            .shadow(color: .theme.inverseBackground.opacity(0.1), radius: 10, y: 5))
                                    })
                                    
                                    NavigationLink(destination: NewEntryView()
                                        .padding(.bottom)
                                        .environment(\.managedObjectContext, context), isActive: $isNewEntryViewActive) {
                                            VStack(spacing: 10) {
                                                Image(systemName: "calendar")
                                                    .foregroundColor(.theme.color)
                                                Text("Check In")
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(width: 115, height: 100)
                                            .background(RoundedRectangle(cornerRadius: cornerRadius)
                                                .fill(Color.theme.secondaryBackground)
                                                .shadow(color: .theme.inverseBackground.opacity(0.1), radius: 10, y: 5))
                                        }
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            showAssistanceView = true
                                            viewRouter.showTabBar = false
                                        }
                                    }, label: {
                                        VStack(spacing: 10) {
                                            Image(systemName: "face.smiling")
                                                .foregroundColor(.theme.color)
                                            Text("Assistance")
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 115, height: 100)
                                        .background(RoundedRectangle(cornerRadius: cornerRadius)
                                            .fill(Color.theme.secondaryBackground)
                                            .shadow(color: .theme.inverseBackground.opacity(0.1), radius: 10, y: 5))
                                        .matchedGeometryEffect(id: "assistance", in: namespace)
                                    })
                                }
                                .padding()
                            }
                        }
                        
                        MakeSpaceForTabBar()
                        
                        Spacer()
                    }
                    .frame(maxWidth: UIScreen.main.bounds.size.width)
                }
            }
            .background(.bar)
            .sheet(isPresented: $showNewActivityView) {
                NewActivityView()
            }
            .sheet(isPresented: $showDailyChallenge) {
                let challenge = context.object(with: (context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URL(string: dailyChallengeID)!))!) as! DailyChallenge
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(challenge.content ?? "There was an error loading the daily challenge")
                            .font(.title.weight(.semibold))
                            .foregroundColor(.theme.background)
                        
                        if !isDailyChallengeCompleted() {
                            Text("Ends in \(Time.shared.hoursMinutesSeconds(seconds: timeRemaining))")
                                .foregroundColor(.theme.background.opacity(0.75))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding()
                    
                    if isDailyChallengeCompleted() {
                        Label("Completed", systemImage: "checkmark")
                            .foregroundColor(.theme.background)
                            .font(.title3)
                    } else {
                        Button(action: {
                            let newDailyAppearance = DailyAppearance(context: context)
                            newDailyAppearance.date = Calendar.current.startOfDay(for: .now)
                            newDailyAppearance.dailyChallenge = challenge
                            
                            do {
                                try context.save()
                            } catch {
                                fatalError("Unresolved CoreData error: Could not save daily appearance data.")
                            }
                        }, label: {
                            Text("Done!")
                                .bold()
                                .foregroundColor(.theme.color)
                                .font(.title3)
                                .frame(width: 150, height: 50)
                                .background(Color.theme.background)
                                .cornerRadius(15)
                        })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.theme.color)
                .presentationDetents([.fraction(0.5)])
            }
            .onReceive(timer) { time in
                guard isActive else { return }
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    dailyChallengeDate = Calendar.current.startOfDay(for: .now)
                    dailyChallengeID = generateDailyChallengeID()
                    resetTimer()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                isActive = newPhase == .active
            }
            .onAppear {
                if dailyChallengeID.isEmpty {
                    dailyChallengeDate = Calendar.current.startOfDay(for: .now)
                    dailyChallengeID = generateDailyChallengeID()
                }
                
                if !Calendar.current.isDateInToday(dailyChallengeDate) {
                    dailyChallengeDate = Calendar.current.startOfDay(for: .now)
                    dailyChallengeID = generateDailyChallengeID()
                }
                
                resetTimer()
                
                if ExternalData.shared.launchedViaEntryReminderNotification {
                    ExternalData.shared.launchedViaEntryReminderNotification = false
                    isNewEntryViewActive = true
                }
            }
        }
    }
    
    // this function returns the current streak of days the user has created entries
    private func getDaysInARow() -> Int {
        if entries.isEmpty {
            return 0
        }
                
        let daysBetween = Calendar.current.dateComponents([.day], from: entries.first!.date!, to: .now).day!
        
        if daysBetween >= 1 {
            return 0
        }
      
        var previous = entries.first!
        var streak = 1
        for index in entries.indices.dropFirst() {
            let sameDay = Calendar.current.isDate(entries[index].date!, equalTo: previous.date!, toGranularity: .day)
            if sameDay {
                continue
            }
            
            let between = Calendar.current.dateComponents([.day], from: entries[index].date!, to: previous.date!).day!
            if between > 1 {
                break
            }
            streak += 1
            
            previous = entries[index]
        }
        
        return streak
    }
    
    // resets the timer when a new day appears
    private func resetTimer() {
        timeRemaining = Int(Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))!.timeIntervalSinceReferenceDate - Date.now.timeIntervalSinceReferenceDate)
    }
    
    private func generateDailyChallengeID() -> String {
        return dailyChallenges.randomElement()!.objectID.uriRepresentation().absoluteString
    }
    
    private func isDailyChallengeCompleted() -> Bool {
        return context.dailyAppearance(from: .now) != nil
    }
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        HomeView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
