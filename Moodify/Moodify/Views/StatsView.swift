//
//  StatsView.swift
//  Moodify
//
//  Created by Raz Frumkin on 03/12/2022.
//

import SwiftUI
import Charts

// a horizontal bar to tell the user which colors reprents which mood
struct ColorsInformationView: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                ForEach(Entry.colorsFromSadToHappy, id: \.self) { color in
                    Rectangle()
                        .fill(color)
                        .frame(width: 50, height: 20)
                }
                Spacer()
            }
            HStack {
                Text(Entry.headersFromSadToHappy.first!)
                Spacer()
                Text(Entry.headersFromSadToHappy.last!)
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

// renders a pie chart of the entries' moods
struct PieChartView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry> // load entries from the database and sort by their dates
    
    let colors: [Color] // colors of the pie slices
    let titles: [String] // titles of the pie slices
    let values: [Double] // values pf the pie slices
    
    let width: CGFloat // width (and height) by pixels of the pie chart (diameter)
    
    private var slices: [PieSliceData] {
        let sum = values.reduce(0, +) // sum all of the values
        var end: Double = 0
        var temporarySlices: [PieSliceData] = []
        
        for (index, value) in values.enumerated() {
            let degrees: Double = value * 360 / sum
            temporarySlices.append(PieSliceData(startAngle: Angle(degrees: end), endAngle: Angle(degrees: end + degrees), value: value * 100 / sum, color: colors[index]))
            end += degrees
        }
        
        return temporarySlices
    }
    
    var body: some View {
        HStack {
            ZStack {
                ForEach(0..<values.count) { index in
                    PieSliceView(data: slices[index])
                }
                .frame(width: width, height: width)
            }
            .padding()
            
            let sum = values.reduce(0, +) // sum all of the values
            
            PieChartRows(colors: colors, titles: titles, values: values.map { String($0) }, percents: values.map { $0 * 100 / sum })
        }
    }
}

// renders the percentage of each pie slice under the pie chart
struct PieChartRows: View {
    let colors: [Color]
    let titles: [String]
    let values: [String]
    let percents: [Double]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(0..<values.count) { index in
                HStack {
                    Circle()
                        .stroke(colors[index], lineWidth: 5)
                        .frame(width: 10, height: 10)
                        .padding(.horizontal, 5)
                    Text(titles[index])
                    Text(String(format: "%.0f%%", percents[index]))
                        .foregroundColor(.gray)
                }
                .frame(alignment: .leading)
            }
        }
    }
}

// renders a slice from a pie chart
struct PieSliceView: View {
    private let minimumPercentageToShowHeader: Double = 5.0
    
    let data: PieSliceData
    
    private var midRadians: Double {
        return .pi / 2 - (data.startAngle + data.endAngle).radians / 2
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let width: CGFloat = min(geometry.size.width, geometry.size.height)
                    let height = width
                    
                    let center = CGPoint(x: width / 2, y: height / 2)
                    
                    path.move(to: center)
                    
                    path.addArc(center: center, radius: width / 2, startAngle: Angle(degrees: -90) + data.startAngle, endAngle: Angle(degrees: -90) + data.endAngle, clockwise: false)
                }
                .fill(data.color)
                
                // if the value is smaller than the minimum percentage to show, don't render the text
                if data.value >= minimumPercentageToShowHeader {
                    Text(String(format: "%.0f%%", data.value))
                        .position(x: geometry.size.width / 2 * CGFloat(1 + 0.78 * cos(midRadians)), y: geometry.size.height / 2 * CGFloat(1 - 0.78 * sin(midRadians)))
                        .foregroundColor(.theme.background)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// wraps pie slice data
struct PieSliceData {
    let startAngle: Angle
    let endAngle: Angle
    let value: Double
    let color: Color
}

// tells the graphs which range of dates to display
enum DayRangeType: String, CaseIterable {
    case sevenDays = "Last 7 Days"
    case thirtyDays = "Last 30 Days"
    case month = "Last Month"
    
    // converts the enum to number of days
    var dayCount: Int {
        switch self {
        case .sevenDays:
            return 7
        case .thirtyDays:
            return 30
        case .month: // returns the number of days between the start of the current month to the current day of the month (for example: December 27th will return 27 days)
            let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: .now)))!
            let daysBetween = Calendar.current.dateComponents([.day], from: start, to: .now).day! + 1
            return daysBetween
        }
    }
}

// store the type of the graph's vertices interpolation
enum GraphInterpolation: String, CaseIterable {
    case curvy = "point.topleft.down.curvedto.point.bottomright.up"
    case sharp = "chart.xyaxis.line"
    case steps = "stairs"
    
    // convert to SwiftUI's interpolation method
    var method: InterpolationMethod {
        switch self {
        case .curvy:
            return .catmullRom
        case .sharp:
            return .linear
        case .steps:
            return .stepCenter
        }
    }
}

// stores the chart type
enum ChartType: String, CaseIterable {
    case bar = "chart.bar.xaxis"
    case pie = "chart.pie.fill"
    case emotions = "face.smiling.fill"
}

// shows the latest moods as a line graph
struct MoodGraphView: View {
    @StateObject var viewRouter: ViewRouter // view router instance
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry> // load entries data for the database and sort them by their dates
    
    private let maximumDaysToShowXAxis: Int = 7
    
    @State private var graphInterpolation: GraphInterpolation = .curvy

    var body: some View {
        let days = viewRouter.statsViewDayRange.dayCount // get day range
        let moods = entries.lastMoods(dayRange: days) // load moods from the day range
        
        VStack(alignment: .leading) {
            HStack {
                Text("Mood Graph")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Picker("Select the graph interpolation", selection: $graphInterpolation) {
                    ForEach(GraphInterpolation.allCases, id: \.rawValue) { value in
                        Image(systemName: value.rawValue)
                            .tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            
            let sortedDates = Array(moods.keys).sorted(by: { $0.compare($1) == .orderedAscending })
            
            Chart {
                ForEach(sortedDates, id: \.self) { key in
                    let y = moods[key]!.0.safeAverage()
                    if y != nil { // if y is nil then the day doesn't have any entries, hence don't include it in the graph
                        let weekDayFormatted = key.formatted(Date.FormatStyle().weekday(.abbreviated))
                        LineMark(x: .value("Day", "\(weekDayFormatted) \(Time.shared.getMonthDay(from: key))"), y: .value("Value", y!))
                            .foregroundStyle(.linearGradient(colors: Entry.colorsFromSadToHappy, startPoint: .bottom, endPoint: .top))
                            .interpolationMethod(graphInterpolation.method)
                        AreaMark(x: .value("Day", "\(weekDayFormatted) \(Time.shared.getMonthDay(from: key))"), y: .value("Value", y!))
                            .foregroundStyle(.linearGradient(colors: Entry.colorsFromSadToHappy.enumerated().map { (index, color) in
                                return color.opacity(Double(index) / 10.0)
                            }, startPoint: .bottom, endPoint: .top))
                            .interpolationMethod(graphInterpolation.method)
                    }
                }
            }
            .chartXAxis(totalDays(sortedDates: sortedDates, moods: moods) > maximumDaysToShowXAxis ? .hidden : .visible) // if there are too many days then don't display the x axis because their headers would overlap
            .chartYScale(domain: 0...100)
            .frame(height: 150)
            Spacer()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(20)
    }
    
    // return the amount of days which have at least one entry
    func totalDays(sortedDates: [Date], moods: MoodsCollection) -> Int {
        var total = 0
        for key in sortedDates {
            if moods[key]!.0.isSafe {
                total += 1
            }
        }
        return total
    }
}

// shows the latest moods as a bar mark chart
struct TotalMoodsChart: View {
    @StateObject var viewRouter: ViewRouter // view router instance
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry> // load entries data for the database and sort them by their dates
        
    @State private var chartType: ChartType = .bar
    
    var body: some View {
        let days = viewRouter.statsViewDayRange.dayCount // get day range
        let moods = entries.lastMoods(dayRange: days) // load moods from the day range
        
        VStack(alignment: .leading) {
            HStack {
                Text("Mood Count")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Picker("Select the chart type", selection: $chartType) {
                    ForEach(ChartType.allCases, id: \.rawValue) { value in
                        Image(systemName: value.rawValue)
                            .tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            
            let moodsTotal = moods.totalMoods() // get an array of the amound of days for each mood
            
            if chartType == .bar {
                Chart {
                    ForEach(Entry.colorsFromSadToHappy.indices, id: \.self) { mood in
                        BarMark(x: .value("Header", Entry.moodToHeader(mood: mood * 20)), y: .value("Value", moodsTotal[mood]))
                            .foregroundStyle(Entry.moodToColor(mood: mood * 20))
                    }
                }
                .frame(height: 150)
            } else if chartType == .pie {
                VStack {
                    GeometryReader { geometry in
                        PieChartView(colors: Entry.colorsFromSadToHappy, titles: Entry.headersFromSadToHappy, values: moodsTotal.map { Double($0) }, width: 175)
                    }
                    .frame(height: 210)
                }
            } else { // the other option is an emotion chart
                HStack {
                    ForEach(Entry.iconsFromSadToHappy.indices, id: \.self) { mood in
                        let color = Entry.moodToColor(mood: mood * 20)
                        Spacer()
                        VStack(spacing: 10) {
                            Image(Entry.moodToIcon(mood: mood * 20))
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(color)
                                .frame(width: 50, height: 50)
                            Text("\(moodsTotal[mood])")
                                .foregroundColor(.theme.background)
                                .font(.title)
                                .bold()
                                .padding(.horizontal)
                                .background(color)
                                .cornerRadius(10)
                        }
                        Spacer()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(20)
    }
}

// shows the latest activities done by the user
struct TotalActivitiesChart: View {
    @StateObject var viewRouter: ViewRouter // view router instance
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry> // load entries data for the database and sort them by their dates
    
    private let minimumToShow: Int = 5
    private let maximumToShow: Int = 10
    
    var body: some View {
        let days = viewRouter.statsViewDayRange.dayCount // get day range
        let moods = entries.lastMoods(dayRange: days) // load moods from the day range
        let activitiesTotal = moods.totalActivities() // get an array of activities and how much each activity has been done by the user
        
        VStack(alignment: .leading) {
            HStack {
                Text("Performed Activities")
                    .font(.title)
                    .bold()
                
                Spacer()
            }
            
            if activitiesTotal.count < minimumToShow {
                Text("Not enough activities yet...")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else {
                let displayedActivitiesTotal = activitiesTotal.sorted { $0.1 > $1.1 }.prefix(maximumToShow)
                
                let most = displayedActivitiesTotal.first!.1
                
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(displayedActivitiesTotal.indices, id: \.self) { index in
                        HStack(spacing: 15) {
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.bar)
                                    .frame(width: 120, height: 20)
                                Capsule()
                                    .fill(.linearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: CGFloat(120 / most * displayedActivitiesTotal[index].1), height: 20)
                            }
                            
                            Image(systemName: displayedActivitiesTotal[index].0.systemName!)
                                .foregroundLinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(width: 10, height: 10)
                            
                            Text(displayedActivitiesTotal[index].0.title!)
                            
                            Text(displayedActivitiesTotal[index].1.formatted())
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(20)
    }
}

// picker used in YearView and CalendarView
enum EntryMemberType: String, CaseIterable {
    case moods = "Moods"
    case activities = "Activities"
    case challenges = "Challenges"
}
// visualizes the user's year by moods, activities and daily challenges
struct YearView: View {
    @Environment(\.managedObjectContext) private var context // database instance
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry> // load entries data for the database and sort them by their dates
    @FetchRequest(sortDescriptors: []) private var activities: FetchedResults<Activity> // load activities data from the database
    
    @State private var year: Int = Calendar.current.component(.year, from: .now) // get the current year
    
    @State private var entryMemberType: EntryMemberType = .moods
    @State private var selectedActivity: Activity? = nil

    @State private var showDailyAppearance: Bool = false
    @State private var selectedDailyAppearance: DailyAppearance?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Yearly \(entryMemberType.rawValue)")
                    .font(.title)
                    .bold()
                
                InformationButton(title: "Yearly \(entryMemberType.rawValue)", message: "Depending on what you select, this is a year panel that will show your moods, activities and daily challenges based on the day they were achieved.")
                
                Spacer()
            }
            
            HStack {
                Button(action: {
                    withAnimation {
                        year -= 1
                    }
                }, label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                })
                
                Text(String(year)) // using the String constructor so no commas would be rendered
                
                Button(action: {
                    withAnimation {
                        year += 1
                    }
                }, label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                })
                .disabled(Calendar.current.component(.year, from: .now) == year) // if the next year is above the current year, do not allow the user to slide to the next year
                                    
                Picker("", selection: $entryMemberType) {
                    ForEach(EntryMemberType.allCases, id: \.rawValue) { value in
                        if value != .activities || !activities.isEmpty {
                            Text(value.rawValue)
                                .tag(value)
                        }
                    }
                }
                .pickerStyle(.menu)
                .accentColor(.secondary)
                
                Spacer()
            }
            
            let start = Calendar.current.date(from: DateComponents(year: year, month: 0, day: 0))! // get start of the year
            let days = Calendar.current.dateComponents([.day], from: start, to: .now).day! + 1 // get the amount of days from the start of the year until now
            let moods = entries.lastMoods(dayRange: days) // get the moods from the current year selected by the picker
            
            HStack(alignment: .top, spacing: 15) {
                VStack {
                    Spacer()
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)")
                            .font(.system(size: 13.13))
                            .foregroundColor(.secondary)
                    }
                }
                                
                ForEach(1...12, id: \.self) { month in
                    VStack(spacing: 3) {
                        Text(String(Time.shared.monthDayFirstLetter(from: month)))
                            .font(.system(size: 13.13))
                            .foregroundColor(.secondary)
                        
                        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Calendar.current.date(from: DateComponents(year: year, month: month))!)!.count
                        ForEach(1...daysInMonth, id: \.self) { day in
                            let dateComponents = DateComponents(year: year, month: month, day: day, hour: 0, minute: 0, second: 0)
                            let date = Calendar.current.date(from: dateComponents)!
                            
                            switch entryMemberType {
                            case .moods:
                                let mood = date > .now ? nil : moods[date]!.0.safeAverage()
                                let color: Color = mood == nil ? .secondary : Entry.moodToColor(mood: Int(mood!))
                                
                                Circle()
                                    .fill(color)
                                    .frame(width: 13, height: 13)
                            case .activities:
                                let activityExists = date > .now ? false : moods[date]!.1.contains(selectedActivity ?? activities.first!)
                                let color: Color = activityExists ? .theme.color : .secondary
                                
                                Circle()
                                    .fill(color)
                                    .frame(width: 13, height: 13)
                            case .challenges:
                                let appearance = context.dailyAppearance(from: date)
                                let color: Color = appearance == nil ? .secondary : .theme.color
                                
                                Circle()
                                    .fill(color)
                                    .frame(width: 13, height: 13)
                                    .onTapGesture {
                                        if appearance != nil {
                                            selectedDailyAppearance = appearance
                                            showDailyAppearance = true
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            if entryMemberType == .moods {
                
                Divider()
                
                let moodsTotal = moods.totalMoods() // get an array of the amound of days for each mood
                
                HStack {
                    ForEach(Entry.iconsFromSadToHappy.indices, id: \.self) { mood in
                        let color = Entry.moodToColor(mood: mood * 20)
                        Spacer()
                        VStack(spacing: 10) {
                            Image(Entry.moodToIcon(mood: mood * 20))
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(color)
                                .frame(width: 50, height: 50)
                            Text(moodsTotal[mood].formatted())
                                .foregroundColor(.theme.secondaryBackground)
                                .font(.body)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(color)
                                .cornerRadius(10)
                        }
                        Spacer()
                    }
                }
                .padding()
            } else if entryMemberType == .activities {
                Picker("Select Activity", selection: $selectedActivity) {
                    ForEach(activities) { activity in
                        Text(activity.title!)
                            .tag(activity as Activity?)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(20)
        .sheet(isPresented: $showDailyAppearance) {
            DailyAppearanceView(appearance: $selectedDailyAppearance)
        }
    }
}

// similar to YearView, but as a monthly calendar
struct CalendarView: View {
    @Environment(\.managedObjectContext) private var context // database instance
    @FetchRequest(sortDescriptors: []) private var entries: FetchedResults<Entry> // entries data
    @FetchRequest(sortDescriptors: []) private var activities: FetchedResults<Activity> // activities data
    
    @State private var entryMemberType: EntryMemberType = .moods
    @State private var selectedActivity: Activity? = nil
    
    @State private var showDailyAppearance: Bool = false
    @State private var selectedDailyAppearance: DailyAppearance?
    
    @State private var currentDate: Date = .now
    @State private var currentMonth: Int = 0
        
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Monthly \(entryMemberType.rawValue)")
                    .font(.title)
                    .bold()
                
                InformationButton(title: "Monthly \(entryMemberType.rawValue)", message: "Depending on what you select, this is a calendar that will show your moods, activities and daily challenges based on the day they were achieved.")
                
                Spacer()
            }
            
            HStack {
                Picker("", selection: $entryMemberType) {
                    ForEach(EntryMemberType.allCases, id: \.rawValue) { value in
                        if value != .activities || !activities.isEmpty {
                            Text(value.rawValue)
                                .tag(value)
                        }
                    }
                }
                .pickerStyle(.menu)
                .accentColor(.secondary)
                
                Spacer()
            }
            
            let moods = entries.toMoodDictionary()
            
            VStack(spacing: 35) {
                let days = Time.shared.generateWeekDaysArray()
                
                HStack(spacing: 20) {
                    let formatted = extractData()
                    VStack(alignment: .leading, spacing: 10) {
                        Text(formatted[0])
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(formatted[1])
                            .font(.title.bold())
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        withAnimation {
                            currentMonth -= 1
                        }
                    }, label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    })
                    
                    Button(action: {
                        withAnimation {
                            currentMonth += 1
                        }
                    }, label: {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    })
                }
                .padding()
                
                HStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                let columns = Array(repeating: GridItem(.flexible()), count: 7)
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(extractDate()) { value in
                        switch entryMemberType {
                        case .moods:
                            cardView(value: value, mood: moods[value.date]?.0)
                        case .activities:
                            cardView(value: value, hasActivity: moods[value.date]?.1.contains(selectedActivity ?? activities.first!))
                        case .challenges:
                            cardView(value: value, appearance: context.dailyAppearance(from: value.date))
                        }
                    }
                }
            }
            
            Divider()
            
            if entryMemberType == .moods {
                ColorsInformationView()
            } else if entryMemberType == .activities {
                Picker("Select Activity", selection: $selectedActivity) {
                    ForEach(activities) { activity in
                        Text(activity.title!)
                            .tag(activity as Activity?)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(20)
        .sheet(isPresented: $showDailyAppearance) {
            DailyAppearanceView(appearance: $selectedDailyAppearance)
        }
    }
    
    // the nullable indicates whether the date exists in entries
    @ViewBuilder func cardView(value: DateValue, mood: DailyMood?) -> some View {
        let color: Color = value.day == -1 ? .clear : mood == nil ? .clear : Entry.moodToColor(mood: Int(mood!.unsafeAverage()))
        VStack {
            if value.day != -1 {
                Text(value.day.formatted())
                    .font(.title3.bold())
            }
        }
        .padding(.vertical, 8)
        .frame(width: 50, height: 60, alignment: .top)
        .background(color)
        .cornerRadius(5)
    }
    
    // the nullable indicates whether the date exists in entries
    @ViewBuilder func cardView(value: DateValue, hasActivity: Bool?) -> some View {
        VStack {
            if value.day != -1 {
                Text(value.day.formatted())
                    .font(.title3.bold())
                if hasActivity != nil && hasActivity! {
                    Circle()
                        .fill(Color.theme.color)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(width: 50, height: 60, alignment: .top)
    }
    
    @ViewBuilder func cardView(value: DateValue, appearance: DailyAppearance?) -> some View {
        VStack {
            if value.day != -1 {
                Text(value.day.formatted())
                    .font(.title3.bold())
                if appearance != nil {
                    Circle()
                        .fill(Color.theme.color)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(width: 50, height: 60, alignment: .top)
        .onTapGesture {
            if appearance != nil {
                selectedDailyAppearance = appearance
                showDailyAppearance = true
            }
        }
    }
    
    // returns a string of the year and month from getCurrentMonth()
    func extractData() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Time.shared.localeIdentifier)
        formatter.dateFormat = "YYYY MMMM"
        let date = formatter.string(from: getCurrentMonth())
        return date.components(separatedBy: " ")
    }
    
    // returns the current month selected by the calendar as a Date object
    func getCurrentMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: currentMonth, to: .now)!
    }
    
    // get all of the dates values of the month selected by the calendar
    func extractDate() -> [DateValue] {
        let currentMonth = getCurrentMonth()
        
        var days = currentMonth.getAllDates().compactMap { date -> DateValue in
            let day = Calendar.current.component(.day, from: date)
            return DateValue(day: day, date: date)
        }
        
        // offset day week
        let firstWeekDay = Calendar.current.component(.weekday, from: days.first?.date ?? .now) + (Time.shared.weekStartsOnSunday() ? 0 : -1)
        for _ in 0..<firstWeekDay - 1 {
            days.insert(DateValue(day: -1, date: .now), at: 0)
        }
        
        return days
    }
}

// struct to store data for each date in the calendar
struct DateValue: Identifiable {
    var id: String = UUID().uuidString
    var day: Int
    var date: Date
}

// daily challenge panel
struct DailyAppearanceView: View {
    @Binding var appearance: DailyAppearance?
    
    var body: some View {
        ZStack {
            Color.theme.color
                .ignoresSafeArea()
            Text(appearance!.dailyChallenge!.content!)
                .foregroundColor(.theme.background)
                .font(.largeTitle)
                .bold()
                .padding()
        }
    }
}

// shows a bar mark chart to display the average mood for each day of the week
struct WeekMoodView: View {
    @FetchRequest(sortDescriptors: []) private var entries: FetchedResults<Entry> // entries data
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Weekly Mood")
                    .font(.title)
                    .bold()
                
                InformationButton(title: "Weekly Mood", message: "This chart displays the average mood per week.")
                
                Spacer()
            }
            
            let moods = entries.toMoodWeekDictionary() // get moods as a dictionary where the key is the day of the week and the value is the average mood in the current day of the week
            let weekDays = Time.shared.generateWeekDaysArray()
            
            Chart {
                ForEach(Array(moods.keys.sorted()), id: \.self) { key in
                    let y = graph(moods: moods[key]!)
                    BarMark(x: .value("Header", weekDays[key - 1]), y: .value("Value", y))
                        .foregroundStyle(Entry.moodToColor(mood: Int(y)))
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 300)
            
            Divider()
            
            ColorsInformationView()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(20)
    }
    
    // get the height of the graph value depending on the moods' average value
    func graph(moods: [DailyMood]) -> Double {
        if moods.isEmpty { return 0 }
        
        var sum = 0.0
        for mood in moods {
            sum += mood.unsafeAverage()
        }
        return sum / Double(moods.count)
    }
}

// visualizes the user's information
struct StatsView: View {
    @StateObject var viewRouter: ViewRouter // view router instance
    
    @Environment(\.managedObjectContext) private var context // database instance
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry> // load entries data for the database and sort them by their dates
        
    var body: some View {
        if entries.isEmpty {
            NoDataView(message: "Not enought data yet to display statistics...", detail: "We require at least one entry in order to display statistics.")
        } else {
            VStack {
                HStack {
                    Text("Show All Time Statistics")
                    InformationButton(title: "All Time Statistics", message: "All time statistics display data which is not dependent on latest entries. Instead it displays all the data you have entered since you've opened this app for the first time.")
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewRouter.showAllTimeStatistics)
                        .labelsHidden()
                }
                .padding()
                
                if !viewRouter.showAllTimeStatistics {
                    Picker("Select the range of entries", selection: $viewRouter.statsViewDayRange) {
                        ForEach(DayRangeType.allCases, id: \.rawValue) { value in
                            Text(value.rawValue)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }
                
                ScrollView {
                    if viewRouter.showAllTimeStatistics {
                        WeekMoodView()
                            .padding()
                        
                        CalendarView()
                            .environment(\.managedObjectContext, context)
                            .padding()
                        
                        YearView()
                            .environment(\.managedObjectContext, context)
                            .padding()
                    } else {
                        MoodGraphView(viewRouter: viewRouter)
                            .padding()
                        
                        TotalMoodsChart(viewRouter: viewRouter)
                            .padding()
                        
                        TotalActivitiesChart(viewRouter: viewRouter)
                            .padding()
                    }
                    
                    MakeSpaceForTabBar()
                }
            }
            .background(Color.theme.background)
        }
    }
}

// this is a preview that only runs on debug mode so ignore the code under when on release mode
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        StatsView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
