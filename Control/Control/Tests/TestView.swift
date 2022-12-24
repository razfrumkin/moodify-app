//
//  TestView.swift
//  Control
//
//  Created by Raz Frumkin on 30/11/2022.
//

/*import SwiftUI

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
                                .onReceive(timer) { _ in
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
        .onReceive(timer, perform: { _ in
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
            
            let features = [
                ("face.smiling", "Entering Your Mood", "You will get a notification daily asking you to input several parameters."),
                ("quote.opening", "Saving Quotes", "If you ever need some inspiration, we offer lots of inspiring quotes."),
                ("chart.line.uptrend.xyaxis", "Diagrams", "Visualize your daily activity using graphs and charts."),
                ("calendar", "Daily Challenge", "Challenge yourself to do random dares every day.   ")
            ]
            
            if showFeatures {
                VStack {
                    ForEach(features.indices, id: \.self) { index in
                        if tick > 10 + Int(10 * Double(index)) {
                            HStack {
                                Image(systemName: features[index].0)
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
                    .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .leading, endPoint: .trailing)
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.5))
        .transition(.opacity)
        .onReceive(timer, perform: { _ in
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
            tick = 0
        }
    }
}

struct TestView: View {
    @State private var showWelcomeAnimation: Bool = true
    
    var body: some View {
        VStack {
            Text("hello lol")
                .foregroundColor(.white)
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.pink)
        }
        .sheet(isPresented: $showWelcomeAnimation) {
            TabView {
                //WelcomeView()
                IntroductionView()
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
*/
