//
//  InformationButton.swift
//  Control
//
//  Created by Raz Frumkin on 03/02/2023.
//

import SwiftUI

struct InformationButton: View {
    @State private var showMessage = false
    let message: String
    let color: Color = .blue

    var body: some View {
        ZStack {
            Button(action: {
                withAnimation {
                    self.showMessage.toggle()
                }
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(color)
            }
            .popover(isPresented: $showMessage) {
                Text(message)
                    .padding()
                    .font(.title3)
                    .presentationDetents([.fraction(0.3)])
            }
        }
    }
}

struct InformationButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.mint
                .ignoresSafeArea()
            InformationButton(message: "Test")
        }
    }
}
