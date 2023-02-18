//
//  Database.swift
//  Moodify
//
//  Created by Raz Frumkin on 27/12/2022.
//

import Foundation
import CoreData
import SwiftUI

extension NSManagedObjectContext {
    // returns a daily appearance from a given date. returns nil if there is no appearance in the given date
    func dailyAppearance(from date: Date) -> DailyAppearance? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DailyAppearance")
        request.predicate = NSPredicate(format: "date == %@", Calendar.current.startOfDay(for: date) as CVarArg)
        request.fetchLimit = 1
        let appearances = try! fetch(request) as! [DailyAppearance]
        if appearances.isEmpty { return nil }
        return appearances.first!
    }
    
    // prepopulate default activity data
    func prepopulateActivites() {
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
            let newActivity = Activity(context: self)
            newActivity.title = activity.0
            newActivity.systemName = activity.1
            
            do {
                try save()
            } catch {
                fatalError("Unresolved CoreData error: Could not prepopulate activity data.")
            }
        }
    }

    // prepopulate quotes data
    func prepopulateQuotes() {
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
                let newQuote = Quote(context: self)
                
                // if the text is empty, then that means the author is unknown and will remain nil
                if (data.count == 1) {
                    newQuote.content = data[0]
                } else {
                    newQuote.author = data[0]
                    newQuote.content = data[1]
                }
                newQuote.isLiked = false
                
                do {
                    try save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not prepopulate quote data.")
                }
            }
        } catch {
            fatalError("Unresolved csv error: Could not parse quotes data.")
        }
    }
    
    // prepopulate daily challenges data
    func prepopulateDailyChallenges() {
        let txtPath = Bundle.main.path(forResource: "DailyChallenges", ofType: "txt")
        if txtPath == nil {
            fatalError("Unresolved path error: Could not fild the daily challenges file in the bundle.")
        }
        var txtData = String?.none
        do {
            txtData = try String(contentsOfFile: txtPath!, encoding: .utf8)
            let challenges = txtData?.split(separator: "\n")
            for challenge in challenges! {
                let newDailyChallenge = DailyChallenge(context: self)
                newDailyChallenge.content = String(challenge)
                
                do {
                    try save()
                } catch {
                    fatalError("Unresolved CoreData error: Could not prepopulate daily challenges data.")
                }
            }
        } catch {
            fatalError("Unresolved txt error: Could not parse daily challenges data.")
        }
    }
}

extension FetchedResults<Activity> {
    // checks if a given systemName exists as an activity
    func imageExists(systemName: String) -> Bool {
        for activity in self {
            if systemName == activity.systemName! {
                return true
            }
        }
        return false
    }
    
    // checks if the title exists as an activity
    func titleExists(title: String) -> Bool {
        for activity in self {
            if title.lowercased() == activity.title!.lowercased() {
                return true
            }
        }
        return false
    }
}
