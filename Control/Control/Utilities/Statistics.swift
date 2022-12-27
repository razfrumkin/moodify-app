//
//  Statistics.swift
//  Control
//
//  Created by Raz Frumkin on 27/12/2022.
//

import Foundation
import SwiftUI

//                          [date: (sum, total,  activities)]
typealias MoodsCollection = [Date: (Int, Int, Set<Activity>)]

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
    func lastMoods(dayRange: Int) -> MoodsCollection {
        let totalDaysAgo = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -dayRange + 1, to: .now)!)
        
        var moods: MoodsCollection = [:]
        let nowStart = Calendar.current.startOfDay(for: .now)
        for index in 0..<dayRange {
            moods[Calendar.current.date(byAdding: .day, value: -index, to: nowStart)!] = (0, 0, [])
        }
        
        for index in indices {
            if self[index].date! < totalDaysAgo {
                break
            }
            
            let date = Calendar.current.startOfDay(for: self[index].date!)
            moods[date]!.0 += Int(self[index].mood)
            moods[date]!.1 += 1
            if self[index].activities == nil {
                continue
            }
            for activity in self[index].activities! {
                moods[date]!.2.insert(activity as! Activity)
            }
        }
        
        return moods
    }
}

class Statistics {
    static let shared: Statistics = Statistics()
    
    // this function returns the average mood per day
    func averageMoodPerDay(moods: MoodsCollection) -> Double {
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
    func safeAverage(mood: MoodsCollection.Value) -> Double? {
        if mood.1 == 0 {
            return nil
        }
        
        return Double(mood.0) / Double(mood.1)
    }
    
    // this functions filters and adds up the moods of dates that repeat and returns the moods a an array of Double
    func totalMoods(moods: MoodsCollection) -> [Int] {
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
    func totalActivities(moods: MoodsCollection) -> [(Activity, Int)] {
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
}
