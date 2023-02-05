//
//  Visuals.swift
//  Control
//
//  Created by Raz Frumkin on 31/12/2022.
//

import Foundation
import SwiftUI

class Visuals {
    static let shared: Visuals = Visuals()
    
    let gradient: [Color] = [.blue, .purple]

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
    
    var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
