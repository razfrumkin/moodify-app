//
//  DetailedEntryView.swift
//  Moodify
//
//  Created by Raz Frumkin on 23/11/2022.
//

import SwiftUI

// renders a given entry in detail
struct DetailedEntryView: View {
    @Environment(\.managedObjectContext) private var context // database instance

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
                        .foregroundColor(.theme.background)
                        .frame(width: 70, height:
                                70)
                    
                    VStack(alignment: .leading) {
                        Text(entry!.header)
                            .font(.title)
                            .bold()
                            .foregroundColor(.theme.background)
                        let formattedTime = Time.shared.formattedDateTime(from: entry!.date!)
                        Text("\(formattedTime.0), \(formattedTime.1), \(String(Calendar.current.dateComponents([.year], from: entry!.date!).year!))") // use the String constructor to prevent commas
                            .foregroundColor(.theme.background.opacity(0.75))
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding(.all, 25)
                .padding(.vertical, 20)
                .background(Color.theme.color)
                
                // display a list of activities only if there are any
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
                                        .foregroundColor(.theme.background)
                                        .frame(width: 200, height: 60)
                                        .background(Color.theme.color)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // display the daily note only if it isn't empty
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
                
                // display the selected quote only if a quote has been selected
                if entry!.quote != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Selected Quote")
                            .font(.title)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\"\(entry!.quote!.content ?? "Unresolved quote")\"")
                                .font(.title.weight(.semibold))
                                .foregroundColor(.theme.background.opacity(0.9))
                            Text("- \(entry!.quote!.author ?? "Unknown")")
                                .foregroundColor(.theme.background.opacity(0.6))
                                .font(.body.italic().bold())
                        }
                        .padding()
                        .background(Color.theme.color)
                        .cornerRadius(15)
                    }
                    .padding()
                    .onTapGesture {
                        selectedQuote = entry!.quote
                        showDetailedLikedQuote = true
                    }
                }
                
                // display the daily challenge for the entry's date only if it has been completed
                let appearance = context.dailyAppearance(from: entry!.date!)
                if appearance != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily Challenge")
                            .font(.title)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(appearance!.dailyChallenge!.content!)
                                .font(.title.weight(.semibold))
                                .foregroundColor(.theme.background.opacity(0.9))
                        }
                        .padding()
                        .background(Color.theme.color)
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
                DetailedQuoteView(quote: $selectedQuote, contentColor: .theme.background.opacity(0.9), authorColor: .theme.background.opacity(0.6))
                    .background(Color.theme.color)
            }
            .sheet(isPresented: $showDailyAppearance) {
                DailyAppearanceView(appearance: $selectedDailyAppearance)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
}
