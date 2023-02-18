//
//  WelcomeView.swift
//  Moodify
//
//  Created by Raz Frumkin on 11/02/2023.
//

import SwiftUI

struct RequestNotificationsView: View {
    @Environment(\.dismiss) private var dismiss // manual dismiss
    
    @AppStorage("reminder") private var reminder: Date = NotificationManager.shared.getDefaultReminder() // sync reminder value from UserDefaults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 5) {
                Text("One more thing")
                    .font(.largeTitle.bold())
                    .foregroundColor(.theme.inverseBackground)
                
                Text("We need you to enable notifications so we can remind you to check-in every day.")
                    .foregroundColor(.theme.inverseBackground)
            }
            
            Button(action: {
                NotificationManager.shared.requestAuthorization() // request the user to enable notifications
                dismiss() // close the sheet
             }, label: {
                 Text("Enable")
                     .frame(maxWidth: .infinity)
                     .foregroundColor(.theme.background)
                     .padding()
                     .background(Color.theme.color)
                     .cornerRadius(15)
            })
            
            DatePicker("Check-In Notification", selection: $reminder, displayedComponents: .hourAndMinute)
                .environment(\.locale, Locale(identifier: Time.shared.localeIdentifier))
                .onChange(of: reminder) { value in
                    NotificationManager.shared.cancelAllNotifications()
                    NotificationManager.shared.scheduleNotification(time: value)
                }
                .tint(.theme.color)
        }
        .multilineTextAlignment(.leading)
        .padding(.all, 50)
    }
}

struct WalkthroughView: View {
    @State var features: [Feature] = []
    
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 20) {
                Text("Walkthrough")
                    .font(.system(size: 50, weight: .heavy))
                    .foregroundColor(.theme.inverseBackground)
                Text("We offer various amount of features, such as:")
                    .foregroundColor(.theme.inverseBackground)
                
                if !features.isEmpty { // this if statement is required because we need to tell SwiftUI that the features have been successfully loaded even though it looks stupid to add an "isEmpty" condition because a for each statement
                    VStack(spacing: 0) {
                        ForEach(features.indices) { index in
                            HStack {
                                Image(systemName: features[index].icon)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.theme.color)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(features[index].title)
                                        .font(.headline.bold())
                                    Text(features[index].detail)
                                }
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.theme.inverseBackground)
                                .padding()
                            }
                        }
                    }
                }

                Spacer()
            }
            .multilineTextAlignment(.leading)
            .padding(.all, 50)
        }
        .onAppear {
            loadFeatures()
        }
    }
    
    // load the features from Features.json
    private func loadFeatures() {
        let decoder = JSONDecoder()
        let url = Bundle.main.url(forResource: "Features", withExtension: "json")!
        do {
            let data = try Data(contentsOf: url)
            do {
                let featuresJSON = try decoder.decode(FeaturesJSON.self, from: data)
                features = featuresJSON.features
            } catch {
                fatalError("Unresolved decoder error: Could not decode the data")
            }
        } catch {
            fatalError("Unresolved bundle error: Could not load the json")
        }
    }
}

struct IntroductionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Welcome to")
                    .font(.system(size: 50, weight: .heavy))
                    .foregroundColor(.theme.inverseBackground)
                
                Text("Moodify")
                    .font(.system(size: 50, weight: .heavy))
                    .foregroundColor(.theme.color)
            }
            
            Text("Track your mood and activities throughout your day.")
            
            Spacer()
            
            Image("appstore")
                .resizable()
                .scaledToFit()
                .cornerRadius(50)
            
            Spacer()
            
            HStack {
                Spacer()
                Text("Developed by Raz Frumkin")
                    .foregroundColor(.theme.inverseBackground)
                    .font(.title3.bold())
                Spacer()
            }
            .padding()
        }
        .multilineTextAlignment(.leading)
        .padding(.all, 50)
    }
}

// features JSON struct
struct FeaturesJSON: Codable {
    let features: [Feature]
}

// features item
struct Feature: Codable {
    let icon: String
    let title: String
    let detail: String
}

struct WelcomeView: View {
    var body: some View {
        TabView {
            IntroductionView()
            WalkthroughView()
            RequestNotificationsView()
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .sheet(isPresented: .constant(true)) {
                WelcomeView()
            }
    }
}
