//
//  ContentView.swift
//  Control
//
//  Created by Raz Frumkin on 25/09/2022.
//

import SwiftUI
import UserNotifications

// this enum points out what tab ContentView is or should be using at the moment
enum Tab {
    case home
    case stats
    case quotes
    case settings
}

// this class tells which tab to use and whether to show the tab bar
class ViewRouter: ObservableObject {
    @Published var currentTab: Tab = .home
    
    @Published var isNewEntryViewActive: Bool = false
    @Published var isEntriesViewActive: Bool = false

    @Published var statsViewDayRange: DayRangeType = .sevenDays
}

// view that shows the icons in the tab bar
struct TabBarIcon: View {
    @StateObject var viewRouter: ViewRouter
    let tab: Tab
    
    let systemName: String
    let title: String
    
    var namespace: Namespace.ID
        
    var body: some View {
        let isSelected = tab == viewRouter.currentTab
        VStack(spacing: 20) {
            if isSelected {
                Rectangle()
                    .fill(.linearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing))
                    .frame(width: 30, height: 3)
                    .matchedGeometryEffect(id: "tabBarSelectedHorizontalLine", in: namespace)
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 30, height: 3)
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
        .foregroundLinearGradient(colors: isSelected ? Utilities.gradient : [.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
        .padding(.horizontal)
        .onTapGesture {
            withAnimation(.easeIn(duration: 0.25)) {
                viewRouter.currentTab = tab
            }
        }
    }
}

// tab bar of ContentView
struct TabBar: View {
    @StateObject var viewRouter: ViewRouter
    
    @Namespace private var namespace
    
    static let height: CGFloat = 115
        
    var body: some View {
        HStack {
            Spacer()
            TabBarIcon(viewRouter: viewRouter, tab: .home, systemName: "house", title: "Home", namespace: namespace)
            Spacer()
            TabBarIcon(viewRouter: viewRouter, tab: .stats, systemName: "chart.bar", title: "Stats", namespace: namespace)
            Spacer()
            TabBarIcon(viewRouter: viewRouter, tab: .quotes, systemName: "lightbulb", title: "Quotes", namespace: namespace)
            Spacer()
            TabBarIcon(viewRouter: viewRouter, tab: .settings, systemName: "gear.circle", title: "Settings", namespace: namespace)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: Self.height, alignment: .top)
        .ignoresSafeArea()
    }
}

// put this where the tabbar occupies space from the view
struct MakeSpaceForTabBar: View {
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: TabBar.height)
    }
}

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
                    .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)
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
                                .fill(.linearGradient(colors: Utilities.gradient, startPoint: .top, endPoint: .bottom))
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
    
    var body: some View {
        VStack {
            Spacer()
            
            if showHeader {
                Text("Introduction")
                    .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)
                    .font(.system(size: 50))
                    .bold()
            }
            
            Spacer()
            
            if showFeatures {
                VStack {
                    ForEach(Utilities.features.indices) { index in
                        if tick > 10 + Int(10 * Double(index)) {
                            HStack(spacing: 10) {
                                Image(systemName: Utilities.features[index].0)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(Utilities.features[index].1)
                                        .bold()
                                    Text(Utilities.features[index].2)
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
                    .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)
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
                    .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)
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

// the main view in the application
struct ContentView: View {
    @StateObject var viewRouter: ViewRouter
    
    @AppStorage("schemeType") private var schemeType: SchemeType = .light
    
    @State private var showWelcomeAnimation: Bool = false
    
    @Environment(\.managedObjectContext) private var context
        
    var body: some View {
        NavigationView {
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
                
                VStack {
                    Spacer()
                    
                    TabBar(viewRouter: viewRouter)
                        .background(.ultraThinMaterial)
                        .cornerRadius(35)
                }
                
                // nav links here
                NavigationLink(destination: NewEntryView(viewRouter: viewRouter, isActive: $viewRouter.isNewEntryViewActive)
                    .padding(.bottom)
                    .environment(\.managedObjectContext, context), isActive: $viewRouter.isNewEntryViewActive) {
                    }
                
                NavigationLink(destination: EntriesView(viewRouter: viewRouter)
                    .environment(\.managedObjectContext, context), isActive: $viewRouter.isEntriesViewActive) {
                        
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
                Utilities.changeColorScheme(scheme: schemeType.colorScheme)
                if UserDefaults.standard.bool(forKey: "firstLaunch") {
                    showWelcomeAnimation = true
                }
                
                UserDefaults.standard.set(false, forKey: "firstLaunch")
                
                if ExternalData.shared.launchedViaEntryReminderNotification {
                    ExternalData.shared.launchedViaEntryReminderNotification = false
                    viewRouter.isNewEntryViewActive = true
                }
            }
            .preferredColorScheme(schemeType.colorScheme)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
                
        ContentView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
