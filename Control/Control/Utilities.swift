//
//  Utilities.swift
//  Control
//
//  Created by Raz Frumkin on 03/11/2022.
//

import Foundation
import CoreData

struct Utilities {
    static public let maximumMood: Double = 99.0
    
    static public func moodToEmoji(mood: Int) -> Character {
        let emojisFromSadToHappy: [Character] = ["😭", "😢", "😔", "☹️", "😕", "😐", "🙂", "😌", "😁", "😃"]

        return emojisFromSadToHappy[mood / 10]
    }
    
    static public func createEmptyEntry(context: NSManagedObjectContext) -> Entry {
        let entry = Entry(context: context)
        entry.mood = 0
        entry.isProductive = false
        return entry
    }
}
