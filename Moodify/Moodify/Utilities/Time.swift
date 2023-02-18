//
//  TimeHelper.swift
//  Moodify
//
//  Created by Raz Frumkin on 26/12/2022.
//

import Foundation

// class that is mainly use to format date and time to strings
class Time {
    static let shared: Time = Time()
    
    // i specifically wanted my application to be in english so i chose the united states as my locale
    let localeIdentifier: String = "en-US"
    
    // checks if the user's week starts on sunday (based on the user's device's locale)
    func weekStartsOnSunday() -> Bool {
        return Calendar.current.firstWeekday == 1
    }
    
    // generates an array of weekdays formatted
    func generateWeekDaysArray() -> [String] {
        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        if weekStartsOnSunday() {
            return days
        }
        
        days.append(days.removeFirst()) // moves sunday to last
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
    
    // converts to string a given date, formats it and seperates it into a pair of two strings
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
    
    // returns a string of both the month and day of a given date
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
    
    // converts some amount of seconds to a hh:mm:ss format (hours, minutes and seconds)
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
    // returns all the dates from the start of the month of the instance date to the end of the month of the instance date
    // for example, the instance date is January 27th, the function will return the range January 1st to January 31th
    func getAllDates() -> [Date] {
        let startDate = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
        
        let range = Calendar.current.range(of: .day, in: .month, for: startDate)!
        
        return range.compactMap { day -> Date in
            return Calendar.current.date(byAdding: .day, value: day - 1, to: startDate)!
        }
    }
    
    // confronts to RawRepresentable so i could store a date inside UserDefaults
    public var rawValue: String {
        return timeIntervalSinceReferenceDate.description
    }
    
    public init?(rawValue: String) {
        self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
    }
}
