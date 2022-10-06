//
//  SettingsView.swift
//  Control
//
//  Created by Raz Frumkin on 05/10/2022.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        Text("Settings View")
            .foregroundColor(.pink)
            .bold()
            .font(.title)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        SettingsView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
