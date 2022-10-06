//
//  EntriesView.swift
//  Control
//
//  Created by Raz Frumkin on 05/10/2022.
//

import SwiftUI

struct EntriesView: View {
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        Text("Entries View")
            .foregroundColor(.pink)
            .bold()
            .font(.title)
    }
}

struct EntriesView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        EntriesView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
