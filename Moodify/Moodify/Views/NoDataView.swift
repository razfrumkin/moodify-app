//
//  NoDataView.swift
//  Moodify
//
//  Created by Raz Frumkin on 05/02/2023.
//

import SwiftUI

// this view should appear when the app has insuffient data of some kind to present to the user
struct NoDataView: View {
    let message: String
    let detail: String
    
    var body: some View {
        ZStack {
            Color.theme.color
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(.largeTitle.weight(.medium))
                    .foregroundColor(.theme.background)
                Text(detail)
                    .font(.title3)
                    .foregroundColor(.theme.background.opacity(0.75))
            }
            .padding()
        }
    }
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct NoDataView_Previews: PreviewProvider {
    static var previews: some View {
        NoDataView(message: "Sufficient data.", detail: "Do something.")
    }
}
