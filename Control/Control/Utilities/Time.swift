//
//  TimeHelper.swift
//  Control
//
//  Created by Raz Frumkin on 26/12/2022.
//

import Foundation

class Time {
    static let shared: Time = Time()
    
    let localeIdentifier: String = "en-CA"
    
    // converts a month in the year to the first letter of the month the number represents
    func monthDayFirstLetter(from: Int) -> Character {
        let monthDays: [Character] = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        
        // january = 1, december = 12, hence "from" is not defined for "from" < 0, "from" > 12. the expected input is 1 <= "from" <= 12
        return monthDays[from - 1]
    }
    
    // returns the month day of a given date
    func getMonthDay(from: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "dd"
        return formatter.string(from: from)
    }
    
    // converts to string a given date and formats it
    func formattedDateTime(from: Date?) -> (String, String) {
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
    func dayOfTheWeekAndDayOfTheMonth(from: Date) -> (String, String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "EEEE"
        let weekDay = formatter.string(from: from)
        formatter.dateFormat = "LLLL d"
        let monthAndDay = formatter.string(from: from)
        
        return (weekDay, monthAndDay)
    }
    
    func hoursMinutesSeconds(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.calendar?.locale = Locale(identifier: localeIdentifier)
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(seconds))!
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
