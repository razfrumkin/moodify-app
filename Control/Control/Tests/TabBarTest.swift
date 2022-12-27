//
//  TabBarTest.swift
//  Control
//
//  Created by Raz Frumkin on 25/12/2022.
//

import SwiftUI

struct SubViewTest: View {
    @StateObject var viewRouter: ViewRouterTest
    
    @Binding var isActive: Bool

    var body: some View {
        ZStack {
            Color.red
                .ignoresSafeArea()
            Text("Sub View")
                .foregroundColor(.white)
                .font(.largeTitle)
                .bold()
        }
    }
}




struct HomeViewTest: View {
    @StateObject var viewRouter: ViewRouterTest

    var body: some View {
        Text("Home View")
    }
}

struct StatsViewTest: View {
    @StateObject var viewRouter: ViewRouterTest

    var body: some View {
        VStack {
            Text("Stats View")
            Button("Press me to\ngo to subview") {
                withAnimation {
                    viewRouter.isSubViewActive = true
                }
            }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
    }
}

struct SettingsViewTest: View {
    @StateObject var viewRouter: ViewRouterTest
    
    var body: some View {
        Text("Settings View")
    }
}

// main
struct TabBarTest: View {
    @StateObject var viewRouter: ViewRouterTest
                
    var body: some View {
        NavigationView {
            ZStack {
                switch viewRouter.currentTab {
                case .home:
                    HomeViewTest(viewRouter: viewRouter)
                case .stats:
                    StatsViewTest(viewRouter: viewRouter)
                case .settings:
                    SettingsViewTest(viewRouter: viewRouter)
                }
                
                VStack {
                    Spacer()
                    
                    TabBarTestNotMainContentView(viewRouter: viewRouter)
                        .background(.ultraThinMaterial)
                        .cornerRadius(35)
                }
                
                NavigationLink(destination: SubViewTest(viewRouter: viewRouter, isActive: $viewRouter.isSubViewActive), isActive: $viewRouter.isSubViewActive) {

                    }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// this enum points out what tab ContentView is or should be using at the moment
enum TabTest {
    case home
    case stats
    case settings
}

// view that shows the icons in the tab bar
struct TabBarIconTest: View {
    @StateObject var viewRouter: ViewRouterTest
    let tab: TabTest
    
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

struct TabBarTestNotMainContentView: View {
    @StateObject var viewRouter: ViewRouterTest
    
    @Namespace private var namespace
        
    var body: some View {
        HStack {
            Spacer()
            TabBarIconTest(viewRouter: viewRouter, tab: .home, systemName: "house", title: "Home", namespace: namespace)
            Spacer()
            TabBarIconTest(viewRouter: viewRouter, tab: .stats, systemName: "chart.bar", title: "Stats", namespace: namespace)
            Spacer()
            TabBarIconTest(viewRouter: viewRouter, tab: .settings, systemName: "gear.circle", title: "Settings", namespace: namespace)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: TabBar.height, alignment: .top)
        .ignoresSafeArea()
    }
}

// this class tells which tab to use and whether to show the tab bar
class ViewRouterTest: ObservableObject {
    @Published var currentTab: TabTest = .home
    
    @Published var isSubViewActive: Bool = false
}

struct TabBarTest_Previews: PreviewProvider {
    static var previews: some View {
        TabBarTest(viewRouter: ViewRouterTest())
    }
}
