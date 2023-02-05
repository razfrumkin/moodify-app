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
    
    @State private var systemImage: String = ""
    @State private var title: String = ""
    
    @State private var library: [IconsCollection] = []
    
    var body: some View {
        Group {
            if !library.isEmpty {
                VStack {
                    VStack {
                        Text("New Activity")
                            .font(.title.bold())
                        
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 100, height: 100)
                            Image(systemName: systemImage.isEmpty ? "questionmark.circle.fill" : systemImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50)
                        }
                        .padding()
                        
                        TextField("Title", text: $title)
                            .multilineTextAlignment(.center)
                            .font(.title.bold())
                            .padding()
                            .background(Color.theme.secondaryBackground)
                            .cornerRadius(10)
                            .lineLimit(1)
                        
                        if title.count < Activity.minimumNameLength || title.count > Activity.maximumNameLength {
                            Text("Activity title must be within \(Activity.minimumNameLength) to \(Activity.maximumNameLength) characters")
                                .foregroundColor(.pink)
                                .padding()
                        }
                        
                        if activityTitleExists() {
                            Text("This activity title already exists.")
                                .foregroundColor(.pink)
                                .padding()
                        }
                        
                        ScrollView {
                            VStack(spacing: 40) {
                                ForEach(library.indices) { section in
                                    VStack(alignment: .leading) {
                                        Text(library[section].title)
                                            .font(.title.bold())
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal,8)
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                                            ForEach(library[section].icons.indices) { index in
                                                let imageExists = activityImageExists(systemName: library[section].icons[index])
                                                let isSelected = library[section].icons[index] == systemImage
                                                ZStack {
                                                    Circle()
                                                        .strokeBorder(.blue, lineWidth: isSelected ? 3 : 0)
                                                        .background(Circle().fill(.white))
                                                        .frame(width: 50, height: 50)
                                                    Image(systemName: library[section].icons[index])
                                                        .scaleEffect(1.2)
                                                        .foregroundColor(.black.opacity(0.5))
                                                        .frame(width: 50, height: 50)
                                                        .cornerRadius(20)
                                                }
                                                .saturation(imageExists ? 0.1 : 1)
                                                .onTapGesture {
                                                    if !imageExists {
                                                        systemImage = library[section].icons[index]
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                        }
                    }
                    .padding()
                    .background(Color.theme.background)
                    
                    let validInput = title.count >= Activity.minimumNameLength && title.count <= Activity.maximumNameLength && !systemImage.isEmpty && !activityTitleExists()
                    
                    VStack {
                        Button(action: {
                            let newActivity = Activity(context: context)
                            
                            newActivity.systemName = systemImage
                            newActivity.title = title
                            
                            do {
                                try context.save()
                            } catch {
                                fatalError("Unresolved CoreData error: Could not create a new activity")
                            }
                            
                            isActive = false
                        }, label: {
                            Text("Create")
                                .bold()
                                .foregroundColor(Color.theme.background)
                                .padding(.vertical)
                                .padding(.horizontal, 150)
                                .background(.blue)
                                .cornerRadius(10)
                                .saturation(validInput ? 1 : 0.1)
                        })
                        .padding()
                    }
                    .background(Color.theme.secondaryBackground)
                    .disabled(!validInput)
                }
            }
        }
        .onAppear {
            loadIconsLibrary()
        }
    }
    
    // checks if a given systemName exists as an activity
    private func activityImageExists(systemName: String) -> Bool {
        for activity in existingActivities {
            if systemName == activity.systemName! {
                return true
            }
        }
        return false
    }
    
    // checks if the title exists as an activity
    private func activityTitleExists() -> Bool {
        for activity in existingActivities {
            if title.lowercased() == activity.title!.lowercased() {
                return true
            }
        }
        return false
    }
    
    struct IconsLibraryJSON: Codable {
        let library: [IconsCollection]
    }
    
    struct IconsCollection: Codable {
        let title: String
        let icons: [String]
    }
    
    private func loadIconsLibrary() {
        let decoder = JSONDecoder()
        let url = Bundle.main.url(forResource: "IconsLibrary", withExtension: "json")!
        do {
            let data = try Data(contentsOf: url)
            do {
                let collection = try decoder.decode(IconsLibraryJSON.self, from: data)
                library = collection.library
            } catch {
                fatalError("Unresolved decoder error: Could not decode the data")
            }
        } catch {
            fatalError("Unresolved bundle error: Could not load the json")
        }
    }
}

struct NewActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared

        Text("")
            .sheet(isPresented: .constant(true)) {
                NewActivityView(isActive: .constant(true))
                    .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
            }
    }
}
