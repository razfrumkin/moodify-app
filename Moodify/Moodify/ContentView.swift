//
//  ContentView.swift
//  Moodify
//
//  Created by Raz Frumkin on 25/09/2022.
//

import SwiftUI

// this class is used to handle data shared by all the views inside ContentView
class ViewRouter: ObservableObject {
    // flag to tell whether the tab bar should be active and rendered
    @Published var showTabBar: Bool = true
    
    // current tab active, for example: HomeView
    @Published var currentTab: Tab = .home
    
    // data that is managed by StatsView, however when exiting StatsView, the data should not reset, hence is stored in the view router
    @Published var showAllTimeStatistics: Bool = true
    @Published var statsViewDayRange: DayRangeType = .sevenDays
    
    init() {
        
    }
}

// put this where the tab bar occupies space from the view so content shouldn't be overlapped by the tab bar
struct MakeSpaceForTabBar: View {
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: TabBar.height)
    }
}

// enum for all possible tabs
enum Tab: String, CaseIterable {
    case home = "Home"          // HomeView
    case stats = "Stats"        // StatsView
    case quotes = "Quotes"      // QuotesView
    case settings = "Settings"  // SettingsView
}

// view that shows the icons in the tab bar
struct TabBarIcon: View {
    // the tab presented
    let tab: Tab
    
    // current tab in the tab bar
    @Binding var currentTab: Tab
    
    // icon of the tab
    let systemName: String
    
    // sharing a namespace to sync animations
    var namespace: Namespace.ID
        
    var body: some View {
        let isSelected = currentTab == tab // check if the current tab selected is this instance's tab
        VStack(spacing: 20) {
            if isSelected { // if it is selected, move the horizontal line above the tab icon
                Capsule()
                    .frame(width: 30, height: 5)
                    .matchedGeometryEffect(id: "tabBarSelectedHorizontalLine", in: namespace)
                    .animation(.easeIn(duration: 0.25))
            } else { // draw an empty horizontal line to fill the void
                Rectangle()
                    .fill(.clear)
                    .frame(width: 30, height: 5)
            }
            VStack(spacing: 5) {
                Image(systemName: "\(systemName)\(isSelected ? ".fill" : "")")
                    .scaleEffect(isSelected ? 1.1 : 1)
                    .font(.system(size: 22))
                                
                Text(tab.rawValue)
                    .scaleEffect(isSelected ? 1.1 : 1)
                    .font(.system(size: 10))
            }
            .frame(alignment: .bottom)
        }
        .foregroundColor(isSelected ? .theme.color : .secondary)
        .shadow(color: .theme.color, radius: isSelected ? 30 : 0)
        .padding(.horizontal)
        .onTapGesture { // if the icon is tapped, set the current tab to this instance's tab
            withAnimation(.easeIn(duration: 0.25)) {
                currentTab = tab
            }
        }
    }
}

// tab bar of ContentView
struct TabBar: View {
    // current tab active, for example: HomeView
    @Binding var currentTab: Tab
    
    // horizontal line animations when tabs are switched
    @Namespace private var namespace
    
    // height of the tab bar
    static let height: CGFloat = 80
        
    var body: some View {
        HStack {
            Spacer()
            TabBarIcon(tab: .home, currentTab: $currentTab, systemName: "house", namespace: namespace)
            Spacer()
            TabBarIcon(tab: .stats, currentTab: $currentTab, systemName: "chart.bar", namespace: namespace)
            Spacer()
            TabBarIcon(tab: .quotes, currentTab: $currentTab, systemName: "lightbulb", namespace: namespace)
            Spacer()
            TabBarIcon(tab: .settings, currentTab: $currentTab, systemName: "gear.circle", namespace: namespace)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.size.width, height: Self.height, alignment: .top)
        .ignoresSafeArea()
    }
}

// the main view in the application
struct ContentView: View {
    @StateObject private var viewRouter: ViewRouter = ViewRouter() // view router instance
    
    @Environment(\.managedObjectContext) private var context // database instance
    @AppStorage("schemeType") private var schemeType: SchemeType = .light // color theme
    
    @State private var showWelcomeView: Bool = false
            
    var body: some View {
        NavigationStack {
            ZStack {
                switch viewRouter.currentTab {
                case .home:
                    HomeView(viewRouter: viewRouter)
                        .environment(\.managedObjectContext, context)
                case .stats:
                    StatsView(viewRouter: viewRouter)
                        .environment(\.managedObjectContext, context)
                case .quotes:
                    QuotesView()
                        .environment(\.managedObjectContext, context)
                case .settings:
                    SettingsView()
                        .environment(\.managedObjectContext, context)
                }
                
                // render the tab bar if the following condition is true
                if viewRouter.showTabBar {
                    VStack {
                        Spacer()
                        TabBar(currentTab: $viewRouter.currentTab)
                            .background(.thinMaterial)
                    }
                }
            }
        }
        .onAppear {
            // set the color theme
            Visuals.shared.changeColorScheme(scheme: schemeType.colorScheme)
            
            // this conditions runs when the application launches for the first time
            if UserDefaults.standard.bool(forKey: "firstLaunch") {
                showWelcomeView = true
                
                // set flag that means the application has already been launched before
                UserDefaults.standard.set(false, forKey: "firstLaunch")
            }
        }
        .sheet(isPresented: $showWelcomeView) {
            WelcomeView()
        }
        .preferredColorScheme(schemeType.colorScheme)
        .edgesIgnoringSafeArea(.bottom)
    }
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
                
        ContentView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
