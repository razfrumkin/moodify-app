//
//  StatsView.swift
//  Control
//
//  Created by Raz Frumkin on 03/12/2022.
//

import SwiftUI
import Charts

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

// renders a pie chart
struct PieChartView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    
    let colors: [Color]
    let titles: [String]
    let values: [Double]
    
    let width: CGFloat
    
    private var slices: [PieSliceData] {
        let sum = values.reduce(0, +)
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
            
            let sum = values.reduce(0, +)
            
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
        case .month:
            let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: .now)))!
            let daysBetween = Calendar.current.dateComponents([.day], from: start, to: .now).day! + 1
            return daysBetween
        }
    }
}

enum GraphInterpolation: String, CaseIterable {
    case curvy = "point.topleft.down.curvedto.point.bottomright.up"
    case sharp = "chart.xyaxis.line"
    case steps = "stairs"
    
    func toInterpolation() -> InterpolationMethod {
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

enum ChartType: String, CaseIterable {
    case bar = "chart.bar.xaxis"
    case pie = "chart.pie.fill"
    case emotions = "face.smiling.fill"
}

struct MoodGraphView: View {
    @StateObject var viewRouter: ViewRouter
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    
    private let maximumDaysToShowXAxis: Int = 7
    
    @State private var graphInterpolation: GraphInterpolation = .curvy

    var body: some View {
        let days = viewRouter.statsViewDayRange.dayCount
        let moods = entries.lastMoods(dayRange: days)
        
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
                    if y != nil {
                        let weekDayFormatted = key.formatted(Date.FormatStyle().weekday(.abbreviated))
                        LineMark(x: .value("Day", "\(weekDayFormatted) \(Time.shared.getMonthDay(from: key))"), y: .value("Value", y!))
                            .foregroundStyle(.linearGradient(colors: Entry.colorsFromSadToHappy, startPoint: .bottom, endPoint: .top))
                            .interpolationMethod(graphInterpolation.toInterpolation())
                        AreaMark(x: .value("Day", "\(weekDayFormatted) \(Time.shared.getMonthDay(from: key))"), y: .value("Value", y!))
                            .foregroundStyle(.linearGradient(colors: Entry.colorsFromSadToHappy.enumerated().map { (index, color) in
                                return color.opacity(Double(index) / 10.0)
                            }, startPoint: .bottom, endPoint: .top))
                            .interpolationMethod(graphInterpolation.toInterpolation())
                    }
                }
            }
            .chartXAxis(totalDays(sortedDates: sortedDates, moods: moods) > maximumDaysToShowXAxis ? .hidden : .visible)
            .chartYScale(domain: 0...100)
            .frame(height: 150)
            Spacer()
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(20)
    }
    
    // TODO: remove this copied function
    func totalDays(sortedDates: [Date], moods: MoodsCollection) -> Int {
        var total = 0
        for key in sortedDates {
            let y = moods[key]!.0.safeAverage()
            if y != nil {
                total += 1
            }
        }
        return total
    }
}

struct TotalMoodsChart: View {
    @StateObject var viewRouter: ViewRouter
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
        
    @State private var chartType: ChartType = .bar
    
    var body: some View {
        let days = viewRouter.statsViewDayRange.dayCount
        let moods = entries.lastMoods(dayRange: days)
        
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
            
            let moodsTotal = moods.totalMoods()
            
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

struct TotalActivitiesChart: View {
    @StateObject var viewRouter: ViewRouter
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    
    private let minimumToShow: Int = 5
    private let maximumToShow: Int = 10
    
    var body: some View {
        let days = viewRouter.statsViewDayRange.dayCount
        let moods = entries.lastMoods(dayRange: days)
        let activitiesTotal = moods.totalActivities()
        
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
                
                let most = displayedActivitiesTotal[0].1
                
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

struct DailyAppearanceView: View {
    @Binding var appearance: DailyAppearance?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(appearance!.dailyChallenge!.content!)
                .font(.largeTitle)
                .bold()
                .padding()
        }
    }
}

// visualizes the user's year
struct YearView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    @FetchRequest(sortDescriptors: []) private var activities: FetchedResults<Activity>
    
    @State private var year: Int = Calendar.current.component(.year, from: .now)
    
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
                
                Text(String(year)) // no commas
                
                Button(action: {
                    withAnimation {
                        year += 1
                    }
                }, label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                })
                .disabled(Calendar.current.component(.year, from: .now) == year)
                                    
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
            
            let start = Calendar.current.date(from: DateComponents(year: year, month: 0, day: 0))!
            let days = Calendar.current.dateComponents([.day], from: start, to: .now).day! + 1
            let moods = entries.lastMoods(dayRange: days)
            
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
                                let color: Color = activityExists ? .mint : .secondary
                                
                                Circle()
                                    .fill(color)
                                    .frame(width: 13, height: 13)
                            case .challenges:
                                let appearance = context.dailyAppearance(from: date)
                                let color: Color = appearance == nil ? .secondary : .mint
                                
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
                
                let moodsTotal = moods.totalMoods()
                
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

struct CalendarView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var entries: FetchedResults<Entry>
    @FetchRequest(sortDescriptors: []) private var activities: FetchedResults<Activity>
    
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
                        .fill(.mint)
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
                        .fill(.mint)
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
    
    func extractData() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Time.shared.localeIdentifier)
        formatter.dateFormat = "YYYY MMMM"
        let date = formatter.string(from: getCurrentMonth())
        return date.components(separatedBy: " ")
    }
    
    func getCurrentMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: currentMonth, to: .now)!
    }
    
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

struct DateValue: Identifiable {
    var id: String = UUID().uuidString
    var day: Int
    var date: Date
}

struct WeekMoodView: View {
    @StateObject var viewRouter: ViewRouter
    
    @FetchRequest(sortDescriptors: []) private var entries: FetchedResults<Entry>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Weekly Mood")
                    .font(.title)
                    .bold()
                
                Spacer()
            }
            
            let moods = entries.toMoodWeekDictionary()
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
    
    func graph(moods: [DailyMood]) -> Double {
        if moods.count == 0 { return 0 }
        
        var sum = 0.0
        for mood in moods {
            sum += mood.unsafeAverage()
        }
        return sum / Double(moods.count)
    }
}

// visualizes the user's information
struct StatsView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
        
    var body: some View {
        if entries.isEmpty {
            NoDataView(message: "Not enought data yet to display statistics...", detail: "We require at least one entry in order to display statistics.")
        } else {
            VStack {
                Toggle("Show All Time Statistics", isOn: $viewRouter.showAllTimeStatistics)
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
                        WeekMoodView(viewRouter: viewRouter)
                            .padding()
                        
                        CalendarView(viewRouter: viewRouter)
                            .environment(\.managedObjectContext, context)
                            .padding()
                        
                        YearView(viewRouter: viewRouter)
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

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceContainer = PersistenceController.shared
        
        StatsView(viewRouter: ViewRouter())
            .environment(\.managedObjectContext, persistenceContainer.container.viewContext)
    }
}
