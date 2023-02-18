//
//  InformationButton.swift
//  Moodify
//
//  Created by Raz Frumkin on 03/02/2023.
//

import SwiftUI

// information button that when tapped should show a sheet with more details aka its information
struct InformationButton: View {
    @State private var showMessage = false
    let title: String
    let message: String
    let color: Color = .theme.color

    var body: some View {
        ZStack {
            Button(action: {
                withAnimation {
                    showMessage = true
                }
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(color)
            }
            .popover(isPresented: $showMessage) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text(title)
                            .font(.title.bold())
                        Spacer()
                    }
                    Text(message)
                        .font(.title3)
                    Spacer()
                }
                .padding()
                .multilineTextAlignment(.leading)
                .presentationDetents([.fraction(0.4)])
            }
        }
    }
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct InformationButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.mint
                .ignoresSafeArea()
            InformationButton(title: "Test", message: "This is a test")
        }
    }
}
