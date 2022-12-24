//
//  DetailedEntryView.swift
//  Control
//
//  Created by Raz Frumkin on 23/11/2022.
//

import SwiftUI

// renders a given entry in detail
struct DetailedEntryView: View {
    @Binding var entry: Entry?
    
    @State private var selectedQuote: Quote?
    @State private var showDetailedLikedQuote: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let icon = Utilities.moodToIcon(mood: Int(entry!.mood))
                let header = Utilities.moodToHeader(mood: Int(entry!.mood))
                let color = Utilities.moodToColor(mood: Int(entry!.mood))

                HStack {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 70, height:
                                70)
                    
                    VStack(alignment: .leading) {
                        Text(header)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        Text(entry!.date!.formatted())
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding()
                    
                    Spacer()
                    
                    let suffix = entry!.isProductive ? ".fill" : ""
                    
                    Image(systemName: "star\(suffix)")
                        .foregroundColor(.white)
                        .font(.title)
                }
                .padding(.all, 25)
                .padding(.vertical, 20)
                .background(color)
                
                if entry!.activities != nil && entry!.activities!.count > 0 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Activities")
                            .font(.title)
                            .bold()
                        
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(entry!.activities!.allObjects as! [Activity]) { activity in
                                    Label(activity.title ?? "REMOVED", systemImage: activity.systemName ?? "x.circle.fill")
                                        .lineLimit(1)
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .frame(width: 200, height: 60)
                                        .background(color)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                if entry!.note != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily Note")
                            .font(.title)
                            .bold()
                        
                        Text(entry!.note!)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding()
                            .background(.bar)
                            .cornerRadius(30)
                            .textSelection(.enabled)
                    }
                    .padding()
                }
                
                if entry!.quote != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Selected Quote")
                            .font(.title)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\"\(entry!.quote!.content ?? "Unresolved quote")\"")
                                .font(.title.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            Text("- \(entry!.quote!.author ?? "Unknown")")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.body.italic().bold())
                        }
                        .padding()
                        .background(color)
                        .cornerRadius(15)
                    }
                    .padding()
                    .onTapGesture {
                        selectedQuote = entry!.quote
                        showDetailedLikedQuote = true
                    }
                }
                
                Spacer()
            }
            .sheet(isPresented: $showDetailedLikedQuote) {
                DetailedQuoteView(quote: $selectedQuote, contentColor: .white.opacity(0.9), authorColor: .white.opacity(0.6))
                    .background(Utilities.moodToColor(mood: Int(entry!.mood)))
            }
        }
    }
}
