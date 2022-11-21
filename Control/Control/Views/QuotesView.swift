//
//  QuotesView.swift
//  Control
//
//  Created by Raz Frumkin on 04/10/2022.
//

import SwiftUI

struct DetailedQuoteView: View {
    @Binding public var quote: (String, String)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\"\(quote.0)\"")
                .font(.title.weight(.semibold))
                .foregroundColor(.pink.opacity(0.9))
                 Text("- \(quote.1)")
                .foregroundColor(.pink.opacity(0.6))
                .font(.body.italic()).bold()
        }
        .frame(width: 350, height: 400)
        .padding()
    }
}

struct LikedQuotesView: View {
    @Environment(\.managedObjectContext) private var context
    @State public var quotes: FetchedResults<Quote>
    
    @State private var showDetailedLikedQuote: Bool = false
    @State private var detailedQuote: (String, String) = ("", "")
        
    var body: some View {
        VStack {
            if atLeastOneLikedQuote() {
                List {
                    ForEach(quotes) { quote in
                        if quote.isLiked {
                            Text("\"\(quote.content ?? "Unresolved quote")\"")
                                .lineLimit(1)
                                .onTapGesture {
                                    detailedQuote = (quote.content ?? "Unresolved quote", quote.author ?? "Unknown")
                                    showDetailedLikedQuote.toggle()
                                }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            quotes[index].isLiked = false
                        }
                    }
                }
            } else {
                Text("You haven't liked any quotes yet")
            }
        }
        .navigationTitle("Liked Quotes")
        .sheet(isPresented: $showDetailedLikedQuote, content: {
            DetailedQuoteView(quote: $detailedQuote)
        })
    }
    
    private func atLeastOneLikedQuote() -> Bool {
        for quote in quotes {
            if quote.isLiked {
                return true
            }
        }
        return false
    }
}

struct QuotesView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var quotes: FetchedResults<Quote>
    
    @State private var quoteIndex: Int = 0
    
    private let maximumLikedQuotes: Int = 50
    @State private var likedQuotesCount: Int = 0
    @State private var showMaximumLikedQuotesAlert = false
            
    var body: some View {
        NavigationView {
            VStack {
                Button("First Launch Mode (\(quotes.count) quote(s))") {
                    for quote in quotes {
                        context.delete(quote)
                    }
                    try? context.save()
                    UserDefaults.standard.set(true, forKey: "firstLaunch")
                    prepopulateData(context: context)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("\"\(quotes[quoteIndex].content ?? "Unresolved quote")\"")
                        .font(.title.weight(.semibold))
                        .foregroundColor(.pink.opacity(0.9))
                    Text("- \(quotes[quoteIndex].author ?? "Unknown")")
                        .foregroundColor(.pink.opacity(0.6))
                        .font(.body.italic().bold())
                }
                .frame(width: 350, height: 400)
                .padding()
                
                HStack {
                    Button(action: {
                        withAnimation {
                            quoteIndex = randomQuoteIndex()
                        }
                    }, label: {
                        Image(systemName: "gobackward")
                            .foregroundColor(.pink)
                            .padding()
                    })
                    .background(.pink.opacity(0.1))
                    .cornerRadius(15)
                    
                    NavigationLink(destination: LikedQuotesView(quotes: quotes).environment(\.managedObjectContext, context)) {
                        HStack {
                            Image(systemName: "heart.square")
                            Text("Liked Quotes")
                        }
                        .foregroundColor(.pink)
                    }
                    .padding()
                    .background(.pink.opacity(0.1))
                    .cornerRadius(15)
                    
                    Button(action: {
                        if quotes[quoteIndex].isLiked {
                            withAnimation {
                                quotes[quoteIndex].isLiked.toggle()
                                
                                do {
                                    try context.save()
                                    likedQuotesCount -= 1
                                } catch {
                                    fatalError("Unresolved CoreData error: Could not unlike the quote")
                                }
                            }
                        } else if likedQuotesCount + 1 > maximumLikedQuotes {
                            showMaximumLikedQuotesAlert = true
                        } else {
                            withAnimation {
                                quotes[quoteIndex].isLiked.toggle()
                                
                                do {
                                    try context.save()
                                    likedQuotesCount += 1
                                } catch {
                                    fatalError("Unresolved CoreData error: Could not like the quote")
                                }
                            }
                        }
                    }, label: {
                        Image(systemName: quotes[quoteIndex].isLiked ? "heart.fill" : "heart")
                            .foregroundColor(.pink)
                            .padding()
                    })
                    .alert("You've hit the limit of liked quotes. (\(maximumLikedQuotes) quotes)", isPresented: $showMaximumLikedQuotesAlert) {
                        Button("Ok", role: .cancel) {
                            
                        }
                    }
                    .background(.pink.opacity(0.1))
                    .cornerRadius(15)
                }
            }
            .onAppear {
                likedQuotesCount = 0
                for quote in quotes {
                    if quote.isLiked {
                        likedQuotesCount += 1
                    }
                }
            }
        }
        .onAppear {
            quoteIndex = Int.random(in: quotes.startIndex..<quotes.endIndex)
        }
    }
    
    private func randomQuoteIndex() -> Int {
        var randomInt = Int.random(in: quotes.startIndex..<(quotes.endIndex - 1))
        if randomInt == quoteIndex {
            randomInt = quotes.endIndex - 1
        }
        return randomInt
    }
}

struct QuotesView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        QuotesView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
