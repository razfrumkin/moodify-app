//
//  DetailedEntryView.swift
//  Control
//
//  Created by Raz Frumkin on 23/11/2022.
//

import SwiftUI

// renders a given entry in detail
struct DetailedEntryView: View {
    @Environment(\.managedObjectContext) private var context

    @Binding var entry: Entry?
    
    @State private var selectedQuote: Quote?
    @State private var selectedDailyAppearance: DailyAppearance?
    @State private var showDetailedLikedQuote: Bool = false
    @State private var showDailyAppearance: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(entry!.icon)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 70, height:
                                70)
                    
                    VStack(alignment: .leading) {
                        Text(entry!.header)
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
                .background(.linearGradient(colors: Utilities.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                
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
                                        .background(.linearGradient(colors: Utilities.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
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
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding()
                            .background(Color.theme.secondaryBackground)
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
                        .background(.linearGradient(colors: Utilities.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(15)
                    }
                    .padding()
                    .onTapGesture {
                        selectedQuote = entry!.quote
                        showDetailedLikedQuote = true
                    }
                }
                
                let appearance = context.dailyAppearance(from: entry!.date!)
                if appearance != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily Challenge")
                            .font(.title)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(appearance!.dailyChallenge!.content!)
                                .font(.title.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .background(.linearGradient(colors: Utilities.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(15)
                    }
                    .padding()
                    .onTapGesture {
                        selectedDailyAppearance = appearance
                        showDailyAppearance = true
                    }
                }
                
                Spacer()
            }
            .sheet(isPresented: $showDetailedLikedQuote) {
                DetailedQuoteView(quote: $selectedQuote, contentColor: .white.opacity(0.9), authorColor: .white.opacity(0.6))
                    .background(.linearGradient(colors: Utilities.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .sheet(isPresented: $showDailyAppearance) {
                DailyAppearanceView(appearance: $selectedDailyAppearance)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
}
