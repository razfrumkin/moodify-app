//
//  HomeView.swift
//  Control
//
//  Created by Raz Frumkin on 04/10/2022.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    
    @State private var isNewEntryViewActive: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: NewEntryView(isActive: $isNewEntryViewActive)
                    .padding(.bottom)
                    .environment(\.managedObjectContext, context), isActive: $isNewEntryViewActive) {
                        Label("New entry", systemImage: "doc.text.image")
                            .foregroundColor(.white)
                            .padding()
                            .background(.pink)
                            .cornerRadius(15)
                    }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        HomeView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
