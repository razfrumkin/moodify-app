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
    static var gradient: [Color] {
        return [.theme.first, .theme.second]
    }
    
    static let features: [(String, String, String)] = [
        ("face.smiling", "Entering Your Mood", "You will get a notification daily asking you to input several parameters."),
        ("heart", "Saving Quotes", "If you ever need some inspiration, we offer lots of inspiring quotes."),
        ("chart.line.uptrend.xyaxis", "Diagrams", "Visualize your daily activity using graphs and charts."),
        ("calendar", "Daily Challenge", "Challenge yourself to do random dares every day.")
    ]
    
    // changes the color scheme of the application
    // https://www.hackingwithswift.com/forums/swiftui/preferredcolorscheme-not-affecting-datepicker-and-confirmationdialog/11796
    static func changeColorScheme(scheme: ColorScheme?) {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)?
            .overrideUserInterfaceStyle = scheme == .light ? .light : .dark
    }
}

extension View {
    func foregroundLinearGradient(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) -> some View {
        overlay {
            LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
        }
        .mask(self)
    }
}

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let background: Color = Color("BackgroundColor")
    let secondaryBackground: Color = Color("SecondaryBackgroundColor")
    
    let first: Color = Color("FirstColor")
    let second: Color = Color("SecondColor")
    
    let moodUpset: Color = Color("MoodUpsetColor")
    let moodSad: Color = Color("MoodSadColor")
    let moodNeutral: Color = Color("MoodNeutralColor")
    let moodGood: Color = Color("MoodGoodColor")
    let moodHappy: Color = Color("MoodHappyColor")
}

enum SchemeType: Int, Identifiable, CaseIterable {
    case light
    case dark
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
