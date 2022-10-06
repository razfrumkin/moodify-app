//
//  ControlApp.swift
//  Control
//
//  Created by Raz Frumkin on 25/09/2022.
//

import SwiftUI
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "Database")
        
        container.loadPersistentStores { description, error in if let error = error as NSError? {
            fatalError("Unresolved CoreData error: \(error)")
        }}
    }
}

@main
struct ControlApp: App {
    var body: some Scene {
        let persistenceContainer = PersistenceController.shared
        
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
                .onAppear {
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    prepopulateData(context: persistenceContainer.container.viewContext)
                }
        }
    }
}
