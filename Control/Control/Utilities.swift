//
//  Utilities.swift
//  Control
//
//  Created by Raz Frumkin on 03/11/2022.
//

import Foundation
import CoreData
import SwiftUI

// a class that provides utitlities for the whole application
class Utilities {
    static let minimumPercentageShow: Double = 5.0
    
    static let maximumMood: Double = 99.0
    static let maximumPreviewActivities: Int = 3
    static let reminderNotificationCategory: String = "reminderNotification"
    
    static let iconsFromSadToHappy: [String] = ["upset", "sad", "neutral", "good", "happy"]
    static let headersFromSadToHappy: [String] = ["Upset", "Sad", "Nuetral", "Good", "Happy"]
    static let colorsFromSadToHappy: [Color] = [.red, .orange, .yellow, .green, .mint]
    
    static let minimumActivityNameLength: Int = 3
    static let maximumActivityNameLength: Int = 15
    
    static let maximumActivitiesToShowInChart: Int = 10
    static let minimumActivitiesToShowInChart: Int = 5
    
    static let localeIdentifier: String = "en-CA"
    
    static let gradient: [Color] = [.pink, .orange]
    static let features: [(String, String, String)] = [
        ("face.smiling", "Entering Your Mood", "You will get a notification daily asking you to input several parameters."),
        ("heart", "Saving Quotes", "If you ever need some inspiration, we offer lots of inspiring quotes."),
        ("chart.line.uptrend.xyaxis", "Diagrams", "Visualize your daily activity using graphs and charts."),
        ("calendar", "Daily Challenge", "Challenge yourself to do random dares every day.")
    ]
    
    // converts a mood to an icon
    static func moodToIcon(mood: Int) -> String {
        return iconsFromSadToHappy[mood / 20]
    }
    
    // converts a mood to a header
    static func moodToHeader(mood: Int) -> String {
        return headersFromSadToHappy[mood / 20]
    }
    
    // converts a mood to a color
    static func moodToColor(mood: Int) -> Color {
        return colorsFromSadToHappy[mood / 20]
    }
    
    // converts a month in the year to the first letter of the month the number represents
    static func monthDayFirstLetter(from: Int) -> Character {
        let monthDays: [Character] = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        
        // january = 1, december = 12, hence "from" is not defined for "from" < 0, "from" > 12. the expected input is 1 <= "from" <= 12
        return monthDays[from - 1]
    }
    
    // returns the month day of a given date
    static func getMonthDay(from: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "dd"
        return formatter.string(from: from)
    }
    
    // converts to string a given date and formats it
    static func formattedDateTime(from: Date?) -> (String, String) {
        if from == nil {
            return ("Unresolved date", "Unresolved time")
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: from!).uppercased()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        let timeString = formatter.string(from: from!)
        
        return (dateString, timeString)
    }
    
    // returns the weekday and month day of a given date
    static func dayOfTheWeekAndDayOfTheMonth(from: Date) -> (String, String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "EEEE"
        let weekDay = formatter.string(from: from)
        formatter.dateFormat = "LLLL d"
        let monthAndDay = formatter.string(from: from)
        
        return (weekDay, monthAndDay)
    }
    
    static func hoursMinutesSeconds(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.calendar?.locale = Locale(identifier: localeIdentifier)
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(seconds))!
    }
    
    // this function takes a range of days and returns all the dates, the overall mood, and the number of times each day repeats
    static func lastMoods(total: Int, entries: FetchedResults<Entry>) -> MoodsCollection {
        if entries.isEmpty {
            return [:]
        }
        
        let totalDaysAgo = Calendar.current.date(byAdding: .day, value: -total + 1, to: .now)!
        let totalDaysAgoClean = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: totalDaysAgo)!
        
        var moods: MoodsCollection = [:]
        let nowClean = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: .now)!
        for index in 0..<total {
            moods[Calendar.current.date(byAdding: .day, value: -index, to: nowClean)!] = (0, 0, [])
        }
        
        for index in entries.indices {
            if entries[index].date! < totalDaysAgoClean {
                break
            }
            
            let date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: entries[index].date!)!
            moods[date]!.0 += Int(entries[index].mood)
            moods[date]!.1 += 1
            if entries[index].activities == nil {
                continue
            }
            for activity in entries[index].activities! {
                moods[date]!.2.insert(activity as! Activity)
            }
        }
        
        return moods
    }
    
    // this function returns the average mood per day
    static func averageMoodPerDay(moods: MoodsCollection) -> Double {
        var sum = 0.0
        for key in Array(moods.keys) {
            let average = safeAverage(mood: moods[key]!)
            if average != nil {
                sum += average!
            }
            
        }
        
        return sum / Double(moods.keys.count)
    }
    
    // this function calculates the average mood per day, but if there are zero days then it will return nil
    static func safeAverage(mood: MoodsCollection.Value) -> Double? {
        if mood.1 == 0 {
            return nil
        }
        
        return Double(mood.0) / Double(mood.1)
    }
    
    // this functions filters and adds up the moods of dates that repeat and returns the moods a an array of Double
    static func totalMoods(moods: MoodsCollection) -> [Int] {
        var data: [Int] = Array(repeating: 0, count: 5)

        for key in moods.keys {
            let average = safeAverage(mood: moods[key]!)
            if average != nil {
                let index = Int(average!) / 20
                data[index] += 1
            }
        }
        
        return data
    }
    
    // this function returns the total appearances of each activities
    static func totalActivities(moods: MoodsCollection) -> [(Activity, Int)] {
        var data: [Activity: Int] = [:]
        
        for key in moods.keys {
            for activity in moods[key]!.2 {
                if activity.title != nil {
                    if data[activity] == nil {
                        data[activity] = 1
                    } else {
                        data[activity]! += 1
                    }
                }
            }
        }
        
        var dataPair: [(Activity, Int)] = []
        
        for key in data.keys {
            dataPair.append((key, data[key]!))
        }
        
        return dataPair
    }
    
    // returns the default reminder time incase the user hasn't set time for the daily notification
    static func getDefaultReminder() -> Date {
        return Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: .now)!
    }
    
    // prepopulate all the default data
    static func prepopulateData(context: NSManagedObjectContext) {
        if UserDefaults.standard.object(forKey: "firstLaunch") == nil {
            UserDefaults.standard.set(true, forKey: "firstLaunch")
            UserDefaults.standard.set(Utilities.getDefaultReminder(), forKey: "reminder")
            UserDefaults.standard.set(true, forKey: "weekStartsOnSunday")
            prepopulateQuotes(context: context)
            prepopulateActivites(context: context)
            prepopulateDailyChallenges(context: context)
        }
    }

    // prepopulate default activity data
    static func prepopulateActivites(context: NSManagedObjectContext) {
        let defaultActivites = [
            ("Running", "figure.run"),
            ("Eating Healthy", "carrot.fill"),
            ("Good Sleep", "bed.double.fill"),
            ("Painting", "paintpalette.fill"),
            ("Took Medication", "pill.fill"),
            ("Television", "tv.fill"),
            ("Music", "headphones"),
            ("Shopping", "bag.fill")
        ]
        
        for activity in defaultActivites {
            let newActivity = Activity(context: context)
            newActivity.title = activity.0
            newActivity.systemName = activity.1
            
            do {
                try context.save()
            } catch {
                fatalError("Unresolved CoreData error: Could not prepopulate activity data.")
            }
        }
    }

    // prepopulate quotes data
    static func prepopulateQuotes(context: NSManagedObjectContext) {
        let csvPath = Bundle.main.path(forResource: "Quotes", ofType: "csv")
        if csvPath == nil {
            fatalError("Unresolved path error: Could not find the quotes file in the bundle.")
        }
        var csvData = String?.none
        do {
            csvData = try String(contentsOfFile: csvPath!, encoding: .utf8)
            let lines = csvData?.replacing("\"", with: "").split(separator: "\n")
            for line in lines! {
                let data = line.split(separator: ",").map(String.init)
                let newQuote = Quote(context: context)
                
                // if the author is unknown
                if (data.count == 1) {
                    newQuote.content = data[0]
                } else {
                    newQuote.author = data[0]
                    newQuote.content = data[1]
                }
                newQuote.isLiked = false
                
                do {
                    try context.save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not prepopulate quote data.")
                }
            }
        } catch {
            fatalError("Unresolved csv error: Could not parse quotes data.")
        }
    }
    
    // prepopulate daily challenges data
    static func prepopulateDailyChallenges(context: NSManagedObjectContext) {
        let txtPath = Bundle.main.path(forResource: "DailyChallenges", ofType: "txt")
        if txtPath == nil {
            fatalError("Unresolved path error: Could not fild the daily challenges file in the bundle.")
        }
        var txtData = String?.none
        do {
            txtData = try String(contentsOfFile: txtPath!, encoding: .utf8)
            let challenges = txtData?.split(separator: "\n")
            for challenge in challenges! {
                let newDailyChallenge = DailyChallenge(context: context)
                newDailyChallenge.content = String(challenge)
                
                do {
                    try context.save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not prepopulate daily challenges data.")
                }
            }
        } catch {
            fatalError("Unresolved txt error: Could not parse daily challenges data.")
        }
    }

}

extension Date: RawRepresentable {
    public var rawValue: String {
        return timeIntervalSinceReferenceDate.description
    }
    
    public init?(rawValue: String) {
        self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
    }
}

extension View {
    func foregroundLinearGradient(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) -> some View {
        self.overlay {
            LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
        }
        .mask(self)
    }
}
