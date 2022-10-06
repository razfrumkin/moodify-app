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
        firstLaunch = false

        prepopulateQuotes(context: context)
    } else {
        
    }
}

func prepopulateQuotes(context: NSManagedObjectContext) {
    let quotes: [(String, String)] = [
        ("Albert Einstein", "We cannot solve problems with the kind of thinking we employed when we came up with them."),
        ("Mahatma Gandhi", "Learn as if you will live forever, live like you will die tomorrow."),
        ("Mark Twain", "Stay away from those people who try to disparage your ambitions. Small minds will always do that, but great minds will give you a feeling that you can become great too."),
        ("Eleanor Roosevelt", "When you give joy to other people, you get more joy in return. You should give a good thought to happiness that you can give out."),
        ("Norman Vincent Peale", "When you change your thoughts, remember to also change your world."),
        ("Walter Anderson", "It is only when we take chances, when our lives improve. The initial and the most difficult risk that we need to take is to become honest. "),
        ("Diane McLaren", "Nature has given us all the pieces required to achieve exceptional wellness and health, but has left it to us to put these pieces together."),
        ("Winston S. Churchill", "Success is not final; failure is not fatal: It is the courage to continue that counts."),
        ("Herman Melville", "It is better to fail in originality than to succeed in imitation."),
        ("Colin R. Davis", "The road to success and the road to failure are almost exactly the same.")
    ]
    
    for quote in quotes {
        let newQuote = Quote(context: context)
        newQuote.author = quote.0
        newQuote.content = quote.1
        newQuote.isLiked = false
        
        do {
            try context.save()
        } catch {
            fatalError("Unresolved CoreData error: Could not prepopulate quote data.")
        }
    }
}
