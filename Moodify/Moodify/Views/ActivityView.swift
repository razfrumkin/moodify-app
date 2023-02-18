//
//  SelectActiviesView.swift
//  Moodify
//
//  Created by Raz Frumkin on 15/11/2022.
//

import SwiftUI

// renders an activity as a label (rounded box which can be tapped if the user wants to select it)
struct ActivityView: View {
    let activity: Activity
    @State var isSelected: Bool = false
    let onToggle: (_ isSelected: Bool) -> Void // on tapped event
        
    @ViewBuilder private var label: some View {
        if isSelected {
            Label(activity.title ?? "Unresolved Activity", systemImage: activity.systemName ?? "x.circle.fill")
            .frame(width: 125, height: 30)
            .background(Color.theme.color)
            .foregroundColor(.white)
        } else {
            Label(activity.title ?? "Unresolved Activity", systemImage: activity.systemName ?? "x.circle.fill")
                .frame(width: 125, height: 30)
                .background(.bar)
                .foregroundColor(.gray)
        }
    }
    
    var body: some View {
        Button(action: {
            
        }, label: {
            label
                .lineLimit(1)
                .font(.caption)
                .cornerRadius(5)
        })
        .simultaneousGesture(TapGesture().onEnded {
            withAnimation {
                isSelected.toggle()
                onToggle(isSelected)
            }
        })
    }
}
