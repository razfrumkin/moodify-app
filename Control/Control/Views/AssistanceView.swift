//
//  AssistanceView.swift
//  Control
//
//  Created by Raz Frumkin on 14/01/2023.
//

import SwiftUI

struct AssistanceView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    
    @Binding var isActive: Bool
    
    @State var namespace: Namespace.ID
    
    private let dayRange: Int = 10
    private let minimumMoods: Int = 5
    
    @State private var item: AssistanceItem?
    @State private var showMore: Bool = false
    
    @State private var mood: Int?
    
    @State private var panels: [AssistancePanel] = []
    
    var body: some View {
        ZStack {
            if mood == nil {
                Color.white
                    .ignoresSafeArea()
            } else {
                Entry.moodToColor(mood: Int(mood!))
                    .ignoresSafeArea()
            }
            
            if mood != nil {
                Image(Entry.moodToIcon(mood: mood!))
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white.opacity(0.15))
                    .frame(width: 300, height: 300)
            }
            
            VStack {
                let collection = entries.lastMoods(dayRange: dayRange).filter { $0.value.0.totalDays > 0 }
                
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
                    
                    let average = collection.unsafeAverageMood()
                    
                    let index = Int(average) / 20
                                        
                    HStack {
                        Text(panels[index].header)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .onAppear {
                        if item == nil {
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
                                
                                if !item!.sources.isEmpty {
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
    
    struct AssistanceJSON: Codable {
        let panels: [AssistancePanel]
    }
    
    struct AssistancePanel: Codable {
        let header: String
        let items: [AssistanceItem]
    }
    
    struct AssistanceItem: Codable {
        let title: String
        let detail: String
        let optionalDetail: String // optional "see more" feature
        let sources: [String] // links to articles
    }
    
    private func loadPanels() {
        let decoder = JSONDecoder()
        let url = Bundle.main.url(forResource: "AssistancePanels", withExtension: "json")!
        do {
            let data = try Data(contentsOf: url)
            do {
                let collection = try decoder.decode(AssistanceJSON.self, from: data)
                panels = collection.panels
            } catch {
                print(data)
                fatalError("Unresolved decoder error: Could not decode the data")
            }
        } catch {
            fatalError("Unresolved bundle error: Could not load the json")
        }
    }
}

struct AssistanceView_Previews: PreviewProvider {
    @Namespace private static var namespace
    
    static var previews: some View {
        AssistanceView(viewRouter: ViewRouter(), isActive: .constant(true), namespace: namespace)
    }
}
