//
//  HomeView.swift
//  Control
//
//  Created by Raz Frumkin on 04/10/2022.
//

import SwiftUI
import CoreData

// this view will open first when the app launches (unless opened via a notification tap)
struct HomeView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    @FetchRequest(sortDescriptors: []) private var dailyChallenges: FetchedResults<DailyChallenge>
    
    @AppStorage("dailyChallengeDate") var dailyChallengeDate: Date = Calendar.current.startOfDay(for: .now)
    @AppStorage("dailyChallengeID") var dailyChallengeID: String = ""
        
    @State private var isNewEntryViewActive: Bool = false
    @State private var showDailyChallenge: Bool = false
    @State private var isEntriesViewActive: Bool = false
    
    @State private var timeRemaining: Int = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isActive: Bool = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.purple)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(getDaysInARow()) day(s) in a row")
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                            
                            let dateHeader = Utilities.dayOfTheWeekAndDayOfTheMonth(from: .now)
                            Text("\(dateHeader.0), \(dateHeader.1)")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.black.opacity(0.5))
                            
                            HStack {
                                let dateComponents = Calendar(identifier: .gregorian).dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
                                let startOfWeek = Calendar(identifier: .gregorian).date(from: dateComponents)!
                                let startOfWeekNoon = Calendar(identifier: .gregorian).date(bySettingHour: 12, minute: 0, second: 0, of: startOfWeek)!
                                
                                // other option is monday
                                let offset = UserDefaults.standard.bool(forKey: "weekStartsOnSunday") ? 1 : 0
                                
                                ForEach(1...7, id: \.self) { day in
                                    let weekDay = Calendar(identifier: .gregorian).date(byAdding: .day, value: day - offset, to: startOfWeekNoon)!
                                    
                                    let isToday = Calendar.current.isDate(weekDay, equalTo: .now, toGranularity: .day)
                                    
                                    Spacer()
                                    VStack(spacing: 5) {
                                        Text(weekDay.formatted(Date.FormatStyle().weekday(.abbreviated)))
                                            .foregroundColor(.white.opacity(0.5))
                                        Text("\(Utilities.getMonthDay(from: weekDay))")
                                            .foregroundColor(.white)
                                            .bold()
                                    }
                                    .padding(.all, 5)
                                    .background(isToday ? .black.opacity(0.25) : .purple)
                                    .cornerRadius(10)
                                    Spacer()
                                }
                            }
                            .padding(.top, 50)
                        }
                        .padding()
                    }
                    .frame(minHeight: 350)
                    
                    NavigationLink(destination: NewEntryView(viewRouter: viewRouter, isActive: $isNewEntryViewActive)
                        .padding(.bottom)
                        .environment(\.managedObjectContext, context), isActive: Binding<Bool>(
                            get: {
                                isNewEntryViewActive
                            }, set: {
                                isNewEntryViewActive = $0
                                viewRouter.showTabBar = !isNewEntryViewActive
                            }
                        )) {
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(.orange)
                                    .frame(maxWidth: .infinity)
                                VStack(alignment: .leading, spacing: 50) {
                                    Text("Check In")
                                        .foregroundColor(.white)
                                        .font(.body)
                                        .bold()
                                    Text("Take a break to tell us how you feel today")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                }
                                .padding()
                            }
                            .cornerRadius(10)
                            .padding()
                        }
                    
                    Button(action: {
                        showDailyChallenge = true
                    }, label: {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(.pink)
                                .frame(maxWidth: .infinity)
                            VStack(alignment: .leading, spacing: 50) {
                                Text("Daily Challenge")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .bold()
                                if isDailyChallengeCompleted() {
                                    Label("Completed", systemImage: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                } else {
                                    Text("Ends in \(Utilities.hoursMinutesSeconds(seconds: timeRemaining))")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                }
                            }
                            .padding()
                        }
                        .cornerRadius(10)
                        .padding()
                    })
                    
                    NavigationLink(destination: EntriesView(viewRouter: viewRouter)
                        .environment(\.managedObjectContext, context), isActive: Binding<Bool>(
                            get: {
                                isEntriesViewActive
                            }, set: {
                                isEntriesViewActive = $0
                                viewRouter.showTabBar = !isEntriesViewActive
                            }
                        )) {
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(.mint)
                                    .frame(maxWidth: .infinity)
                                VStack(alignment: .leading, spacing: 50) {
                                    Text("List of Entries")
                                        .foregroundColor(.white)
                                        .font(.body)
                                        .bold()
                                    Text("Check out the history of your entries")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                }
                                .padding()
                            }
                            .cornerRadius(10)
                            .padding()
                        }
                    }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showDailyChallenge) {
            let challenge = context.object(with: (context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URL(string: dailyChallengeID)!))!) as! DailyChallenge
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(challenge.content ?? "There was an error loading the daily challenge")
                        .font(.title.weight(.semibold))
                        .foregroundColor(.white)
                    
                    if isDailyChallengeCompleted() {
                        Text("Daily challenged has been completed")
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("Ends in \(Utilities.hoursMinutesSeconds(seconds: timeRemaining))")
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding()
                
                if isDailyChallengeCompleted() {
                    Label("Completed", systemImage: "checkmark")
                        .foregroundColor(.white)
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
                            .foregroundColor(.pink)
                            .frame(width: 150, height: 50)
                            .background(.white)
                            .cornerRadius(15)
                    })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.pink)
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
                dailyChallengeID = generateDailyChallengeID()
            }
            
            let dailyChallengeDateClean = Calendar.current.startOfDay(for: dailyChallengeDate)
            let daysBetween = Calendar.current.dateComponents([.day], from: dailyChallengeDateClean, to: .now).day!
            if daysBetween > 0 {
                dailyChallengeID = generateDailyChallengeID()
            }
            
            resetTimer()
            
            if ExternalData.shared.launchedViaEntryReminderNotification {
                ExternalData.shared.launchedViaEntryReminderNotification = false
                isNewEntryViewActive = true
                viewRouter.showTabBar = false
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
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DailyAppearance")
        request.predicate = NSPredicate(format: "date == %@", Calendar.current.startOfDay(for: .now) as CVarArg)
        request.fetchLimit = 1
        return try! context.count(for: request) > 0
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        HomeView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
