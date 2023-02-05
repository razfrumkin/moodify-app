//
//  Statistics.swift
//  Control
//
//  Created by Raz Frumkin on 27/12/2022.
//

import Foundation
import SwiftUI

//                          [date: (sum, total,  activities)]
typealias MoodsCollection = [Date: (DailyMood, Set<Activity>)]

// use only if the dictionary isn't empty, otherwise it would crash because a division by zero error
extension MoodsCollection {
    func unsafeAverageMood() -> Double {
        var sum = 0.0
        var validDays = 0
        
        for key in keys {
            let average = self[key]!.0.safeAverage()
            if average != nil {
                sum += average!
                validDays += 1
            }
        }
        
        return sum / Double(validDays)
    }
    
    // this functions filters and adds up the moods of dates that repeat and returns the moods a an array of Double
    func totalMoods() -> [Int] {
        var data: [Int] = Array(repeating: 0, count: 5)

        for key in keys {
            let average = self[key]!.0.safeAverage()
            if average != nil {
                let index = Int(average!) / 20
                data[index] += 1
            }
        }
        
        return data
    }
    
    // this function returns the total appearances of each activities
    func totalActivities() -> [(Activity, Int)] {
        var data: [Activity: Int] = [:]
        
        for key in keys {
            for activity in self[key]!.1 {
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
}

extension FetchedResults<Quote> {
    // checks if the user has liked at least one quote
    var atLeastOneLikedQuote: Bool {
        for quote in self {
            if quote.isLiked { return true }
        }
        return false
    }
}

extension FetchedResults<Entry> {
    func toMoodWeekDictionary() -> [Int: [DailyMood]] {
        var data: [Int: [DailyMood]] = [:]
                
        for day in 1...7 {
            data[day] = []
        }
        
        let dictionary = toMoodDictionary()
        
        for key in dictionary.keys {
            data[Calendar.current.component(.weekday, from: key)]!.append(dictionary[key]!.0)
        }
        
        return data
    }
    
    func toMoodDictionary() -> MoodsCollection {
        var data: MoodsCollection = [:]
        
        for entry in self {
            let date = Calendar.current.startOfDay(for: entry.date!)
            if data[date] == nil {
                data[date] = (DailyMood(sum: Int(entry.mood), totalDays: 1), Set<Activity>())
                if entry.activities != nil {
                    for activity in entry.activities as! Set<Activity> {
                        data[date]?.1.insert(activity)
                    }
                }
            } else {
                data[date]!.0.sum += Int(entry.mood)
                data[date]!.0.totalDays += 1
                if entry.activities != nil {
                    for activity in entry.activities as! Set<Activity> {
                        data[date]?.1.insert(activity)
                    }
                }
            }
        }
        
        return data
    }
    
    func lastMoods(dayRange: Int) -> MoodsCollection {
        let totalDaysAgo = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -dayRange + 1, to: .now)!)
        
        var moods: MoodsCollection = [:]
        let nowStart = Calendar.current.startOfDay(for: .now)
        for index in 0..<dayRange {
            moods[Calendar.current.date(byAdding: .day, value: -index, to: nowStart)!] = (DailyMood(), [])
        }
        
        for index in indices {
            if self[index].date! < totalDaysAgo {
                break
            }
            
            let date = Calendar.current.startOfDay(for: self[index].date!)
            moods[date]!.0.sum += Int(self[index].mood)
            moods[date]!.0.totalDays += 1
            if self[index].activities == nil {
                continue
            }
            for activity in self[index].activities! {
                moods[date]!.1.insert(activity as! Activity)
            }
        }
        
        return moods
    }
}

enum EntryMemberType: String, CaseIterable {
    case moods = "Moods"
    case activities = "Activities"
    case challenges = "Challenges"
}

struct DailyMood {
    var sum: Int
    var totalDays: Int
    
    init() {
        sum = 0
        totalDays = 0
    }
    
    init(sum: Int, totalDays: Int) {
        self.sum = sum
        self.totalDays = totalDays
    }
    
    // this function calculates the average mood for a given day, but if there are zero days then it will return nil
    func safeAverage() -> Double? {
        if totalDays == 0 {
            return nil
        }
        
        return Double(sum) / Double(totalDays)
    }
    
    // this function calculates the average mood for a given day, can throw an exception if the amount of days is zero
    func unsafeAverage() -> Double {
        return Double(sum) / Double(totalDays)
    }
    
    var isSafe: Bool {
        return totalDays != 0
    }
}
