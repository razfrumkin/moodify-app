//
//  ContentView.swift
//  Control
//
//  Created by Raz Frumkin on 25/09/2022.
//

import SwiftUI

// the view that welcomes the user
struct WelcomeView: View {
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var tick: Int = 0
    
    @State private var showLogo: Bool = false
    @State private var showDescription: Bool = false
    @State private var showGraph: Bool = false
    @State private var showAuthor: Bool = false
    
    @State private var heights: [Double] = Array(repeating: 0.0, count: 10)
    
    var body: some View {
        VStack(spacing: 5) {
            Spacer()
            
            if showLogo {
                Text("Control")
                    .foregroundLinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
                    .font(.system(size: 75))
            }
            
            if showDescription {
                Text("Track your days.")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
            
            Spacer()
            
            if showGraph {
                HStack(spacing: 10) {
                    let values = [0.9, 0.8, 0.55, 0.6, 0.55, 0.35, 0.5, 0.4, 0.75, 0.6]
                    ForEach(values.indices, id: \.self) { index in
                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(.bar)
                                .frame(width: 20, height: 150)
                            
                            Capsule()
                                .fill(.linearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                                .frame(width: 20, height: heights[index])
                                .animation(.spring(dampingFraction: 0.25).delay(0.05 * Double(index)))
                                .onReceive(timer) { time in
                                    if tick == 20 {
                                        withAnimation {
                                            heights[index] = 150 * values[index]
                                        }
                                    }
                                }
                        }
                    }
                }
            }
            
            Spacer()
                            
            if showAuthor {
                Text("Made by Raz Frumkin")
                    .bold()
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.5))
        .transition(.opacity)
        .onReceive(timer, perform: { time in
            tick += 1
            if tick == 1 {
                showLogo = true
            } else if tick == 5 {
                showDescription = true
            } else if tick == 10 {
                showAuthor = true
            } else if tick == 15 {
                showGraph = true
            }
        })
    }
}

// the view that introduces the user to the features the app has to offer
struct IntroductionView: View {
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var tick: Int = 0
    
    @State private var showHeader: Bool = false
    @State private var showFeatures: Bool = false
    @State private var showPrivacyHeader: Bool = false
    
    private let features: [(String, String, String)] = [
        ("face.smiling", "Entering Your Mood", "You will get a notification daily asking you to input several parameters."),
        ("heart", "Saving Quotes", "If you ever need some inspiration, we offer lots of inspiring quotes."),
        ("chart.line.uptrend.xyaxis", "Diagrams", "Visualize your daily activity using graphs and charts."),
        ("calendar", "Daily Challenge", "Challenge yourself to do random dares every day.")
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            if showHeader {
                Text("Introduction")
                    .foregroundLinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
                    .font(.system(size: 50))
                    .bold()
            }
            
            Spacer()
            
            if showFeatures {
                VStack {
                    ForEach(features.indices) { index in
                        if tick > 10 + Int(10 * Double(index)) {
                            HStack(spacing: 10) {
                                Image(systemName: features[index].0)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(features[index].1)
                                        .bold()
                                    Text(features[index].2)
                                }
                            }
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.bar)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
            
            if showPrivacyHeader {
                Label("Your data is private", systemImage: "lock.fill")
                    .foregroundLinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.5))
        .transition(.opacity)
        .onReceive(timer, perform: { time in
            tick += 1
            if tick == 1 {
                showHeader = true
            } else if tick == 5 {
                showFeatures = true
            } else if tick == 55 {
                showPrivacyHeader = true
            }
        })
        .onAppear {
            timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
            tick = 0
            showHeader = false
            showFeatures = false
            showPrivacyHeader = false
        }
    }
}

// the view that requests authorization from the user to send a notification to their device
struct RequestNotificationView: View {
    @State private var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var tick: Int = 0
    
    @State private var showOneMoreThingHeader: Bool = false
    @State private var showRequestNotificationHeader: Bool = false
    @State private var showNotificationsOptions: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            
            if showOneMoreThingHeader {
                Text("One more thing")
                    .font(.largeTitle)
            } else if showRequestNotificationHeader {
                Text("We need you to enable notifications")
            }
            
            if showNotificationsOptions {
                VStack {
                    Button(action: {
                        NotificationManager.shared.requestAuthorization()
                    }, label: {
                        Text("Enable")
                    })
                    
                    Button("No thanks") {
                        
                    }
                    .foregroundLinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
                }
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.5))
        .transition(.opacity)
        .onReceive(timer, perform: { _ in
            tick += 1
            if tick == 1 {
                showOneMoreThingHeader = true
            } else if tick == 5 {
                showOneMoreThingHeader = false
                showRequestNotificationHeader = true
            } else if tick == 10 {
                showNotificationsOptions = true
            }
        })
    }
}

// this class tells which tab to use and whether to show the tab bar
class ViewRouter: ObservableObject {
    @Published var showTabBar: Bool = true
    @Published var currentTab: Tab = .home
    
    @Published var showAllTimeStatistics: Bool = true
    @Published var statsViewDayRange: DayRangeType = .sevenDays
    
    init() {
        
    }
}

// put this where the tabbar occupies space from the view
struct MakeSpaceForTabBar: View {
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 115) // TODO: change to a constant
    }
}

enum Tab: String, CaseIterable {
    case home
    case stats
    case quotes
    case settings
}

// view that shows the icons in the tab bar
struct TabBarIcon: View {
    let tab: Tab
    
    @Binding var currentTab: Tab
    
    let systemName: String
    let title: String
    
    var namespace: Namespace.ID
        
    var body: some View {
        let isSelected = currentTab == tab
        VStack(spacing: 20) {
            if isSelected {
                Capsule()
                    .frame(width: 30, height: 5)
                    .matchedGeometryEffect(id: "tabBarSelectedHorizontalLine", in: namespace)
                    .animation(.easeIn(duration: 0.25))
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 30, height: 5)
            }
            VStack(spacing: 5) {
                Image(systemName: "\(systemName)\(isSelected ? ".fill" : "")")
                    .scaleEffect(isSelected ? 1.1 : 1)
                    .font(.system(size: 22))
                                
                Text(title)
                    .scaleEffect(isSelected ? 1.1 : 1)
                    .font(.system(size: 10))
            }
            .frame(alignment: .bottom)
        }
        .foregroundColor(isSelected ? .purple : .secondary)
        .shadow(color: .purple, radius: isSelected ? 30 : 0)

        .padding(.horizontal)
        .onTapGesture {
            withAnimation(.easeIn(duration: 0.25)) {
                currentTab = tab
            }
        }
    }
}

// tab bar of ContentView
struct TabBar: View {
    @Binding var currentTab: Tab
    
    @Namespace private var namespace
    
    static let height: CGFloat = 80
        
    var body: some View {
        HStack {
            Spacer()
            TabBarIcon(tab: .home, currentTab: $currentTab, systemName: "house", title: "Home", namespace: namespace)
            Spacer()
            TabBarIcon(tab: .stats, currentTab: $currentTab, systemName: "chart.bar", title: "Stats", namespace: namespace)
            Spacer()
            TabBarIcon(tab: .quotes, currentTab: $currentTab, systemName: "lightbulb", title: "Quotes", namespace: namespace)
            Spacer()
            TabBarIcon(tab: .settings, currentTab: $currentTab, systemName: "gear.circle", title: "Settings", namespace: namespace)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.size.width, height: Self.height, alignment: .top)
        .ignoresSafeArea()
    }
}

// the main view in the application
struct ContentView: View {
    @StateObject private var viewRouter: ViewRouter = ViewRouter()
    
    @Environment(\.managedObjectContext) private var context
    @AppStorage("schemeType") private var schemeType: SchemeType = .light
    
    @State private var showWelcomeAnimation: Bool = false
        
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
                    QuotesView(viewRouter: viewRouter)
                        .environment(\.managedObjectContext, context)
                case .settings:
                    SettingsView(viewRouter: viewRouter)
                        .environment(\.managedObjectContext, context)
                }
                
                if viewRouter.showTabBar {
                    VStack {
                        Spacer()
                        Group {
                            TabBar(currentTab: $viewRouter.currentTab)
                                .background(.thinMaterial)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showWelcomeAnimation) {
            TabView {
                WelcomeView()
                IntroductionView()
                RequestNotificationView()
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .onAppear {
            Visuals.shared.changeColorScheme(scheme: schemeType.colorScheme)
            if UserDefaults.standard.bool(forKey: "firstLaunch") {
                showWelcomeAnimation = true
            }
            
            UserDefaults.standard.set(false, forKey: "firstLaunch")
        }
        .preferredColorScheme(schemeType.colorScheme)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
                
        ContentView()
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
