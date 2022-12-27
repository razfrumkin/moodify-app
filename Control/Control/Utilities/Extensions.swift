//
//  Extensions.swift
//  Control
//
//  Created by Raz Frumkin on 27/12/2022.
//

import Foundation
import SwiftUI
import CoreData

extension Entry {
    static let maximumMood: Double = 99.0
    
    static let iconsFromSadToHappy: [String] = ["upset", "sad", "neutral", "good", "happy"]
    static let headersFromSadToHappy: [String] = ["Upset", "Sad", "Nuetral", "Good", "Happy"]
    static let colorsFromSadToHappy: [Color] = [.theme.moodUpset, .theme.moodSad, .theme.moodNeutral, .theme.moodGood, .theme.moodHappy]
    
    var icon: String { return Self.moodToIcon(mood: Int(mood)) }
    var header: String { return Self.moodToHeader(mood: Int(mood)) }
    var color: Color { return Self.moodToColor(mood: Int(mood)) }
    
    // converts any mood to an icon
    static func moodToIcon(mood: Int) -> String {
        return iconsFromSadToHappy[mood / 20]
    }
    
    // converts any mood to a header
    static func moodToHeader(mood: Int) -> String {
        return headersFromSadToHappy[mood / 20]
    }
    
    // converts any mood to a color
    static func moodToColor(mood: Int) -> Color {
        return colorsFromSadToHappy[mood / 20]
    }
}
