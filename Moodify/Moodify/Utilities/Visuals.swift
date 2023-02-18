//
//  Visuals.swift
//  Moodify
//
//  Created by Raz Frumkin on 31/12/2022.
//

import Foundation
import SwiftUI

// class to handle mainly color theme related concepts
class Visuals {
    static let shared: Visuals = Visuals()
    
    // changes the color scheme of the application
    // https://www.hackingwithswift.com/forums/swiftui/preferredcolorscheme-not-affecting-datepicker-and-confirmationdialog/11796
    func changeColorScheme(scheme: ColorScheme) {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)?
            .overrideUserInterfaceStyle = scheme == .light ? .light : .dark
    }
}

extension View {
    // a helper function to draw foreground gradients
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

// load the color themes from the bundle
struct ColorTheme {
    let background: Color = Color("BackgroundColor")
    let secondaryBackground: Color = Color("SecondaryBackgroundColor")
    let inverseBackground: Color = Color("InverseBackgroundColor")
    
    let moodUpset: Color = Color("MoodUpsetColor")
    let moodSad: Color = Color("MoodSadColor")
    let moodNeutral: Color = Color("MoodNeutralColor")
    let moodGood: Color = Color("MoodGoodColor")
    let moodHappy: Color = Color("MoodHappyColor")

    // main application color theme (this color is widely used across the application)
    let color: Color = Color(red: 145.0 / 255.0, green: 145.0 / 255.0, blue: 233 / 255)
}

// scheme type enum
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
    
    var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
