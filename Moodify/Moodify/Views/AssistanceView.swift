//
//  AssistanceView.swift
//  Moodify
//
//  Created by Raz Frumkin on 14/01/2023.
//

import SwiftUI

// assist the user based on the latest moods
struct AssistanceView: View {
    @StateObject var viewRouter: ViewRouter // view router instance
    
    @Environment(\.managedObjectContext) private var context // database instance
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry> // load entries data for the database and sort them by their dates
    
    @Binding var isActive: Bool
        
    @State var namespace: Namespace.ID // animations between the panel and the parent view (HomeView)
    
    private let dayRange: Int = 10 // the amount of latest days to analyze data
    private let minimumMoods: Int = 5 // minimum moods (days with entries) required to assist the user
    
    @State private var item: AssistanceItem? // random assistance panel
    @State private var showMore: Bool = false // flag to verify whether some assistance panel has more detail
    
    @State private var mood: Int?
    
    @State private var panels: [AssistancePanel] = []
    
    var body: some View {
        ZStack {
            if mood == nil { // if the moods hasn't loaded yet, set the background to the color theme's appearance
                Color.theme.color
                    .ignoresSafeArea()
            } else { // else set the color to match the mood
                Entry.moodToColor(mood: Int(mood!))
                    .ignoresSafeArea()
            }
            
            if mood != nil { // draw the mood with little-to-no opacity as an icon
                Image(Entry.moodToIcon(mood: mood!))
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white.opacity(0.15))
                    .frame(width: 300, height: 300)
            }
            
            VStack {
                // load only the latest days from the day range that have at least one entry
                let collection = entries.lastMoods(dayRange: dayRange).filter { $0.value.0.isSafe }
                
                if collection.count < minimumMoods {
                    ZStack {
                        NoDataView(message: "Not enough data to assist you...", detail: "We require at least \(minimumMoods) check-ins from different days in the last \(dayRange) in order to assist you. Otherwise, our assistance will not be accurate.")
                        HStack {
                            Button(action: {
                                withAnimation {
                                    viewRouter.showTabBar = true
                                    isActive = false
                                }
                            }, label: {
                                VStack {
                                    Label("Back", systemImage: "chevron.left")
                                        .padding()
                                        .background(.clear)
                                    Spacer()
                                }
                            })
                            
                            Spacer()
                        }
                    }
                } else if !panels.isEmpty {
                    HStack {
                        Button(action: {
                            withAnimation {
                                viewRouter.showTabBar = true
                                isActive = false
                            }
                        }, label: {
                            Label("Back", systemImage: "chevron.left")
                                .padding()
                        })
                        
                        Spacer()
                    }
                    
                    // calculate the average mood
                    let average = collection.unsafeAverageMood()
                    
                    // get index of moods array based on the average mood (it's 20 because there are 5 moods and the mood range is 0.0-99.0, or in other words 100 divided by 5 is 20)
                    let index = Int(average) / 20
                                        
                    HStack {
                        Text(panels[index].header)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .onAppear {
                        if item == nil { // load a random panel only if the current panel is random to prevent it loading every update to the UI (when tapping "see more", SwiftUI automatically updates the UI)
                            item = panels[index].items.randomElement()!
                        }
                        mood = Int(average)
                    }
                    
                    if item != nil {
                        ScrollView {
                            VStack(spacing: 10) {
                                HStack {
                                    Text(item!.title)
                                        .font(.title.bold())
                                        .padding()
                                    
                                    Spacer()
                                }
                                
                                Text(item!.detail)
                                    .font(.title3.bold())
                                    .padding()
                                
                                // show the "see more" option if the detail isn't empty
                                if !item!.optionalDetail.isEmpty {
                                    Button(action: {
                                        withAnimation {
                                            showMore.toggle()
                                        }
                                    }, label: {
                                        VStack {
                                            Text("See \(showMore ? "less" : "more")")
                                                .bold()
                                            Image(systemName: "chevron.\(showMore ? "up" : "down")")
                                                .bold()
                                        }
                                        .foregroundColor(.white)
                                    })
                                    
                                    if showMore {
                                        Text(item!.optionalDetail)
                                            .font(.title3)
                                            .padding()
                                            .cornerRadius(5)
                                    }
                                }
                                
                                // show the link sources if the links array isn't empty
                                VStack(spacing: 5) {
                                    ForEach(item!.sources.indices, id: \.self) { index in
                                        Link(destination: URL(string: item!.sources[index])!) {
                                            HStack {
                                                Text("- Source \(index + 1)")
                                                    .foregroundColor(.blue)
                                                    .bold()
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .frame(minHeight: 600)
                    }
                }
            }
            .onAppear {
                loadPanels()
            }
        }
        .matchedGeometryEffect(id: "assistance", in: namespace)
    }
    
    // load the assistance panels from AssistancePanels.json
    private func loadPanels() {
        let decoder = JSONDecoder()
        let url = Bundle.main.url(forResource: "AssistancePanels", withExtension: "json")!
        do {
            let data = try Data(contentsOf: url)
            do {
                let collection = try decoder.decode(AssistanceJSON.self, from: data)
                panels = collection.panels
            } catch {
                fatalError("Unresolved decoder error: Could not decode the data")
            }
        } catch {
            fatalError("Unresolved bundle error: Could not load the json")
        }
    }
}

// assistance JSON struct
struct AssistanceJSON: Codable {
    let panels: [AssistancePanel]
}

// assistance panel
struct AssistancePanel: Codable {
    let header: String
    let items: [AssistanceItem]
}

// assistance item
struct AssistanceItem: Codable {
    let title: String
    let detail: String
    let optionalDetail: String // optional "see more" feature
    let sources: [String] // links to articles
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct AssistanceView_Previews: PreviewProvider {
    @Namespace private static var namespace
    
    static var previews: some View {
        AssistanceView(viewRouter: ViewRouter(), isActive: .constant(true), namespace: namespace)
    }
}
