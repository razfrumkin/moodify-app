//
//  HomeView.swift
//  Control
//
//  Created by Raz Frumkin on 04/10/2022.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        Text("Home View")
            .foregroundColor(.pink)
            .bold()
            .font(.title)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        HomeView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
