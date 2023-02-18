//
//  NewActivityView.swift
//  Moodify
//
//  Created by Raz Frumkin on 22/11/2022.
//

import SwiftUI

// this view allows the user to pick an icon to use for a new activity and set a title for the activity
struct NewActivityView: View {
    @Environment(\.dismiss) private var dismiss // manual dismiss
    @Environment(\.managedObjectContext) private var context // database instance
    @FetchRequest(sortDescriptors: []) private var existingActivities: FetchedResults<Activity> // load the activities data to tell which icons and names have been used already
    
    @State private var systemImage: String = ""
    @State private var title: String = ""
    
    @State private var library: [IconsCollection] = []
    
    var body: some View {
        Group {
            // render only when the icons library has been successfully loaded
            if !library.isEmpty {
                VStack {
                    VStack {
                        Text("New Activity")
                            .font(.title.bold())
                        
                        ZStack {
                            Circle()
                                .fill(Color.theme.color)
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
                        
                        // display an error if the title isn't within the character bounds
                        if title.count < Activity.minimumNameLength || title.count > Activity.maximumNameLength {
                            Text("Activity title must be within \(Activity.minimumNameLength) to \(Activity.maximumNameLength) characters")
                                .foregroundColor(.pink)
                                .padding()
                        }
                        
                        // display an error if the title already exists
                        if existingActivities.titleExists(title: title) {
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
                                            .padding(.horizontal,8)
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                                            ForEach(library[section].icons.indices) { index in
                                                let imageExists = existingActivities.imageExists(systemName: library[section].icons[index])
                                                let isSelected = library[section].icons[index] == systemImage
                                                ZStack {
                                                    Circle()
                                                        .strokeBorder(Color.theme.color, lineWidth: isSelected ? 3 : 0)
                                                        .background(Circle().fill(Color.theme.secondaryBackground))
                                                        .frame(width: 50, height: 50)
                                                    Image(systemName: library[section].icons[index])
                                                        .scaleEffect(1.2)
                                                        .foregroundColor(.theme.color)
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
                    
                    let validInput = title.count >= Activity.minimumNameLength && title.count <= Activity.maximumNameLength && !systemImage.isEmpty && !existingActivities.titleExists(title: title)
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
                            
                            dismiss()
                        }, label: {
                            Text("Create")
                                .bold()
                                .foregroundColor(Color.theme.background)
                                .padding(.vertical)
                                .padding(.horizontal, 150)
                                .background(Color.theme.color)
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
    
    // icons library JSON struct
    struct IconsLibraryJSON: Codable {
        let library: [IconsCollection]
    }
    
    // icons library item
    struct IconsCollection: Codable {
        let title: String
        let icons: [String]
    }
    
    // load the icons library from IconsLibrary.json
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

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct NewActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared

        Text("")
            .sheet(isPresented: .constant(true)) {
                NewActivityView()
                    .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
            }
    }
}
