//
//  ContentView.swift
//  Control
//
//  Created by Raz Frumkin on 25/09/2022.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var selectedTab: Tab = .home

    init() {
        UITabBar.appearance().isHidden = true
    }
        
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                switch selectedTab {
                case .home:
                    HomeView()
                        .environment(\.managedObjectContext, context)
                case .entries:
                    EntriesView()
                        .environment(\.managedObjectContext, context)
                case .quotes:
                    QuotesView()
                        .environment(\.managedObjectContext, context)
                case .settings:
                    SettingsView()
                        .environment(\.managedObjectContext, context)
                }
            }
            
            VStack {
                Spacer()
                TabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea()
        }
    }
}

enum Tab: String, CaseIterable {
    case home
    case entries
    case quotes
    case settings
}

struct TabBar: View {
    @Binding public var selectedTab: Tab
    
    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Spacer()
                
                let imageAndHeader: (String, String) = {
                    switch tab {
                    case .home:
                        return ("house", "Home")
                    case .entries:
                        return ("rectangle.grid.1x2", "Entries")
                    case .quotes:
                        return ("lightbulb", "Quotes")
                    case .settings:
                        return ("gear.circle", "Settings")
                    }
                }()
                
                VStack(spacing: 5) {
                    Image(systemName: selectedTab == tab ? imageAndHeader.0 + ".fill" : imageAndHeader.0)
                        .scaleEffect(tab == selectedTab ? 1.1 : 1)
                        .foregroundColor(selectedTab == tab ? .pink : .gray)
                        .font(.system(size: 22))
                    Text(imageAndHeader.1)
                        .scaleEffect(tab == selectedTab ? 1.1 : 1)
                        .foregroundColor(selectedTab == tab ? .pink : .gray)
                        .font(.system(size: 10))
                }
                .onTapGesture {
                    withAnimation(.easeIn(duration: 0.1)) {
                        selectedTab = tab
                    }
                }
                
                Spacer()
            }
        }
        .frame(width: nil, height: 80, alignment: .top)
        .padding(.top, 10)
        .background(.white)
        .cornerRadius(16)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        ContentView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
            .onAppear {
                prepopulateData(context: persistenceContainer.container.viewContext)
            }
    }
}
