//
//  NoDataView.swift
//  Control
//
//  Created by Raz Frumkin on 05/02/2023.
//

import SwiftUI

struct NoDataView: View {
    let message: String
    let detail: String
    
    var body: some View {
        ZStack {
            LinearGradient(colors: Visuals.shared.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(.largeTitle.weight(.medium))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding()
        }
    }
}

struct NoDataView_Previews: PreviewProvider {
    static var previews: some View {
        NoDataView(message: "Sufficient data.", detail: "Do something.")
    }
}
