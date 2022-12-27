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
        
    @State private var showDailyChallenge: Bool = false
    
    @State private var timeRemaining: Int = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isActive: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.linearGradient(colors: Utilities.gradient, startPoint: UnitPoint.topLeading, endPoint: .bottomTrailing))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        VStack(alignment: .leading, spacing: 10) {
                            Spacer()
                            Text("\(getDaysInARow()) day(s) in a row")
                                .font(.title)
                                .bold()
                                .foregroundColor(.theme.background)
                            
                            let dateHeader = Time.shared.dayOfTheWeekAndDayOfTheMonth(from: .now)
                            Text("\(dateHeader.0), \(dateHeader.1)")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.theme.background.opacity(0.5))
                            
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
                                            .foregroundColor(.theme.background.opacity(0.5))
                                        Text("\(Time.shared.getMonthDay(from: weekDay))")
                                            .foregroundColor(.theme.background)
                                            .bold()
                                    }
                                    .padding(.all, 5)
                                    .background(isToday ? .black.opacity(0.25) : .clear)
                                    .cornerRadius(10)
                                    Spacer()
                                }
                            }
                            .padding(.top, 50)
                        }
                        .padding()
                    }
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
                    
                    Spacer()
                }
                
                ScrollView {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 300)
                    VStack(spacing: 20) {
                        Button(action: {
                            viewRouter.isNewEntryViewActive = true
                        }, label: {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.accentColor)
                                Image("checkIn")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.theme.background.opacity(0.3))
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150)
                                    .position(x: 300, y: 100)
                                VStack(alignment: .leading, spacing: 50) {
                                    Text("Check In")
                                        .font(.body)
                                        .bold()
                                    Text("Take a break to tell us how you feel today")
                                        .font(.title3)
                                }
                                .padding()
                            }
                            .foregroundColor(.theme.background)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .padding()
                        })
                        
                        
                        Button(action: {
                            showDailyChallenge = true
                        }, label: {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.linearGradient(colors: Utilities.gradient, startPoint: UnitPoint.topLeading, endPoint: .bottomTrailing))
                                Image("dailyChallenge")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.theme.background.opacity(0.3))
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150)
                                    .position(x: 300, y: 100)
                                VStack(alignment: .leading, spacing: 50) {
                                    Text("Daily Challenge")
                                        .font(.body)
                                        .bold()
                                    if isDailyChallengeCompleted() {
                                        Label("Completed", systemImage: "checkmark")
                                            .font(.title3)
                                    } else {
                                        Text("Ends in \(Time.shared.hoursMinutesSeconds(seconds: timeRemaining))")
                                            .font(.title3)
                                    }
                                }
                                .padding()
                            }
                            .foregroundColor(.theme.background)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .padding()
                        })
                        
                        Button(action: {
                            viewRouter.isEntriesViewActive = true

                        }, label: {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.linearGradient(colors: Utilities.gradient, startPoint: UnitPoint.topLeading, endPoint: .bottomTrailing))
                                Image("entries")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.theme.background.opacity(0.3))
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150)
                                    .position(x: 300, y: 100)
                                    .frame(maxWidth: .infinity, maxHeight: 150)
                                VStack(alignment: .leading, spacing: 50) {
                                    Text("List of Entries")
                                        .font(.body)
                                        .bold()
                                    Text("Check out the history of your entries")
                                        .font(.title3)
                                }
                                .padding()
                            }
                            .foregroundColor(.theme.background)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .padding()
                        })
                    }
                    
                    MakeSpaceForTabBar()
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
                            .foregroundLinearGradient(colors: Utilities.gradient, startPoint: UnitPoint.topLeading, endPoint: .bottomTrailing)                        
                            .font(.title3)
                            .frame(width: 150, height: 50)
                            .background(.white)
                            .cornerRadius(15)
                    })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.linearGradient(colors: Utilities.gradient, startPoint: UnitPoint.topLeading, endPoint: .bottomTrailing))
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        HomeView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
