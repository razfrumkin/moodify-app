//
//  Prepopulate.swift
//  Control
//
//  Created by Raz Frumkin on 25/09/2022.
//

import Foundation
import SwiftUI
import CoreData

func prepopulateData(context: NSManagedObjectContext) {
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    
    if firstLaunch {
        prepopulateQuotes(context: context)
        
        firstLaunch = false
    } else {
        
    }
}

func prepopulateQuotes(context: NSManagedObjectContext) {
    let csvPath = Bundle.main.path(forResource: "Quotes", ofType: "csv")
    if csvPath == nil {
        fatalError("Unresolved path error: Could not find the quotes file in the bundle.")
    }
    var csvData: String? = nil
    do {
        csvData = try String(contentsOfFile: csvPath!, encoding: String.Encoding.utf8)
        let lines = csvData?.replacing("\"", with: "").split(separator: "\n")
        for line in lines! {
            let data = line.split(separator: ",").map(String.init)
            let newQuote = Quote(context: context)
            
            // if the author is unknown
            if (data.count == 1) {
                newQuote.content = data[0]
            } else {
                newQuote.author = data[0]
                newQuote.content = data[1]
            }
            newQuote.isLiked = false
            
            do {
                try context.save()
            } catch {
                fatalError("Unresolved CoreData error: Could not prepopulate quote data.")
            }
        }
    } catch {
        fatalError("Unresolved csv error: Could not parse quotes data.")
    }
}
