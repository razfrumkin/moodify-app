//
//  SelectActiviesView.swift
//  Control
//
//  Created by Raz Frumkin on 15/11/2022.
//

import SwiftUI

struct ActivityView: View {
    public var activity: Activity
    @State public var isSelected: Bool = false
    public var onToggle: (_ isSelected: Bool) -> Void
        
    @ViewBuilder private var label: some View {
        if isSelected {
            HStack {
                Image(systemName: activity.systemName ?? "x.circle.fill")
                Text(activity.title ?? "Unresolved Title")
            }
            .frame(width: 125, height: 30)
            .background(.purple)
            .foregroundColor(.white)
        } else {
            HStack {
                Image(systemName: activity.systemName ?? "x.circle.fill")
                Text(activity.title ?? "Unresolved Title")
            }
            .frame(width: 125, height: 30)
            .background(.bar)
            .foregroundColor(.gray)
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                isSelected.toggle()
                onToggle(isSelected)
            }
        }, label: {
            label
                .font(.caption)
                .cornerRadius(5)
        })
    }
}
