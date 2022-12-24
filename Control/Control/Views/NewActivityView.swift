//
//  NewActivityView.swift
//  Control
//
//  Created by Raz Frumkin on 22/11/2022.
//

import SwiftUI

// this view allows the user to pick an icon to use for a new activity
struct NewActivityView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var existingActivities: FetchedResults<Activity>
    
    @Binding var isActive: Bool
    
    @State private var showAlert: Bool = false
        
    @State private var activitySystemImage: String = ""
    @State private var activityTitle: String = ""
    @State private var activityTitleError: Bool = false
            
    private let images: [String: [String]] = [
        "Nature":
            ["globe.americas.fill", "sun.min.fill", "moon.fill", "sparkles", "cloud.fill", "wind", "drop.fill", "flame.fill", "bolt.fill", "leaf.fill", "carrot.fill", "atom"],
        "Animals":
            ["hare.fill", "tortoise.fill", "lizard.fill", "bird.fill", "ant.fill", "ladybug.fill", "fish.fill", "pawprint.fill"],
        "Fitness":
            ["figure.walk", "figure.run", "figure.roll", "figure.baseball", "figure.cooldown", "figure.strengthtraining.functional", "figure.lacrosse", "figure.mind.and.body", "figure.outdoor.cycle", "figure.skating", "figure.yoga", "figure.flexibility", "dumbbell.fill", "tennis.racket", "soccerball.inverse", "baseball.fill", "basketball.fill", "football.fill", "cricket.ball.fill", "tennisball.fill", "volleyball.fill"],
        "Health":
            ["lungs.fill", "eye.fill", "ear.fill", "heart.fill", "cross.case.fill", "microbe.fill", "medical.thermometer.fill", "bandage.fill", "syringe.fill", "facemask.fill", "pill.fill", "ivfluid.bag.fill", "waveform.path.ecg.rectangle.fill"],
        "Home":
            ["house.fill", "lightbulb.fill", "fanblades.fill", "lamp.desk.fill", "spigot.fill", "shower.fill", "bathtub.fill", "bed.double.fill", "sofa.fill", "washer.fill", "dryer.fill", "dishwasher.fill", "oven.fill", "microwave.fill", "refrigerator.fill", "sink.fill", "toilet.fill", "av.remote.fill", "tv.fill"],
        "Transportation":
            ["airplane", "car.fill", "bolt.car.fill", "tram.fill", "cablecar.fill", "ferry.fill", "train.side.front.car", "box.truck.fill", "scooter", "sailboat.fill", "bicycle"],
        "Editing":
            ["pencil", "eraser.fill", "scissors", "paintbrush.fill", "paintbrush.pointed.fill", "paintpalette.fill"],
        "Devices":
            ["gamecontroller.fill", "headphones", "camera.fill", "clock.fill", "stopwatch.fill", "hourglass"],
        "Other":
            ["fuelpump.fill", "bag.fill"]
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 60) {
                    ForEach(Array(images.keys).sorted(), id: \.self) { key in
                        VStack(alignment: .leading) {
                            Text(key)
                                .font(.title.bold())
                                .foregroundColor(.pink)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                                ForEach(images[key]!, id: \.self) { image in
                                    let imageExists = activityImageExists(systemName: image)
                                    Button(action: {
                                        if !imageExists {
                                            activitySystemImage = image
                                            showAlert = true
                                        }
                                    }, label: {
                                        Image(systemName: image)
                                            .scaleEffect(1.2)
                                            .foregroundColor(.purple)
                                            .frame(width: 50, height: 50)
                                            .background(.purple.opacity(0.2))
                                            .cornerRadius(20)
                                            .saturation(imageExists ? 0.1 : 1)
                                    })
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .alert("New Activity", isPresented: $showAlert, actions: {
                TextField("Activity title here...", text: $activityTitle)
                
                Button("Create") {
                    if activityTitle.count >= Utilities.minimumActivityNameLength && activityTitle.count <= Utilities.maximumActivityNameLength {
                        let newActivity = Activity(context: context)
                        
                        newActivity.systemName = activitySystemImage
                        newActivity.title = activityTitle
                        
                        do {
                            try context.save()
                        } catch {
                            fatalError("Unresolved CoreData error: Could not create a new activity")
                        }
                        
                        activitySystemImage = ""
                        activityTitle = ""
                        
                        isActive = false
                    } else {
                        activityTitleError = true
                    }
                }
                Button("Cancel", role: .cancel) {
                    activitySystemImage = ""
                    activityTitle = ""
                }
            }, message: {
                Text("Activity title must be within \(Utilities.minimumActivityNameLength) to \(Utilities.maximumActivityNameLength) characters")
            })
            .alert("Inavlid Activity Title", isPresented: $activityTitleError, actions: {
                Button("Okay", role: .cancel) {
                    activitySystemImage = ""
                    activityTitle = ""
                }
            }, message: {
                Text("\"\(activityTitle)\" is not within \(Utilities.minimumActivityNameLength) to \(Utilities.maximumActivityNameLength) characters")
            })
            .navigationTitle("New Activity")
        }
    }
    
    // checks if a given systemName exists as an activity
    func activityImageExists(systemName: String) -> Bool {
        for activity in existingActivities {
            if systemName == activity.systemName! {
                return true
            }
        }
        return false
    }
}

struct NewActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared

        NewActivityView(isActive: .constant(true))
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
