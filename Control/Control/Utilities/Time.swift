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
    
    func weekStartsOnSunday() -> Bool {
        return Calendar.current.firstWeekday == 1
    }
    
    // generates an array of weekdays formatted
    func generateWeekDaysArray() -> [String] {
        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        if weekStartsOnSunday() {
            return days
        }
        
        days.append(days.removeFirst())
        return days
    }
    
    // converts a month in the year to the first letter of the month the number represents
    func monthDayFirstLetter(from month: Int) -> Character {
        let monthDays: [Character] = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        
        // january = 1, december = 12, hence "from" is not defined for "from" < 0, "from" > 12. the expected input is 1 <= "from" <= 12
        return monthDays[month - 1]
    }
    
    // returns the month day of a given date
    func getMonthDay(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    // converts to string a given date and formats it
    func formattedDateTime(from date: Date?) -> (String, String) {
        if date == nil {
            return ("Unresolved date", "Unresolved time")
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: date!).uppercased()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        let timeString = formatter.string(from: date!)
        
        return (dateString, timeString)
    }
    
    func monthAndDay(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // returns the weekday and month day of a given date
    func dayOfTheWeekAndDayOfTheMonth(from date: Date) -> (String, String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = "EEEE"
        let weekDay = formatter.string(from: date)
        formatter.dateFormat = "LLLL d"
        let monthAndDay = formatter.string(from: date)
        
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
    func getAllDates() -> [Date] {
        let startDate = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
        
        let range = Calendar.current.range(of: .day, in: .month, for: startDate)!
        
        return range.compactMap { day -> Date in
            return Calendar.current.date(byAdding: .day, value: day - 1, to: startDate)!
        }
    }
    
    public var rawValue: String {
        return timeIntervalSinceReferenceDate.description
    }
    
    public init?(rawValue: String) {
        self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
    }
}
