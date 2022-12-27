//
//  StatsView.swift
//  Control
//
//  Created by Raz Frumkin on 03/12/2022.
//

import SwiftUI
import Charts

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
    
    // returns the sheet detent depending on the chart type
    var detent: PresentationDetent {
        switch self {
        case .bar:
            return .fraction(0.4)
        case .pie:
            return .fraction(0.4)
        case .emotions:
            return .fraction(0.2)
        }
    }
}

struct MoodGraphView: View {
    @StateObject var viewRouter: ViewRouter
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    
    private let maximumDaysToShowXAxis: Int = 8
    
    @State private var graphInterpolation: GraphInterpolation = .curvy

    var body: some View {
        let days = viewRouter.statsViewDayRange.dayCount
        let moods = entries.lastMoods(dayRange: days)
        
        VStack {
            HStack {
                Picker("Select the graph interpolation", selection: $graphInterpolation) {
                    ForEach(GraphInterpolation.allCases, id: \.rawValue) { value in
                        Image(systemName: value.rawValue)
                            .tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                
                Spacer()
                                
                let averageMoodPerDay = Statistics.shared.averageMoodPerDay(moods: moods)
                let color = Entry.moodToColor(mood: Int(averageMoodPerDay))
                HStack {
                    Text("Average mood:")
                    Text(Entry.moodToHeader(mood: Int(averageMoodPerDay)))
                        .foregroundColor(color)
                        .bold()
                }
                .cornerRadius(10)
                
                Spacer()
            }
            
            let sortedDates = Array(moods.keys).sorted(by: { $0.compare($1) == .orderedAscending })

            Chart {
                ForEach(sortedDates, id: \.self) { key in
                    let y = Statistics.shared.safeAverage(mood: moods[key]!)
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
            .frame(height: 250)
            Spacer()
        }
        .padding()
        .background(Color.theme.background)
    }
    
    // TODO: remove this copied function
    func totalDays(sortedDates: [Date], moods: MoodsCollection) -> Int {
        var total = 0
        for key in sortedDates {
            let y = Statistics.shared.safeAverage(mood: moods[key]!)
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
    
    @Binding var chartDetent: PresentationDetent
    
    @State private var chartType: ChartType = .bar
    
    var body: some View {
        let days = viewRouter.statsViewDayRange.dayCount
        let moods = entries.lastMoods(dayRange: days)
        
        VStack(spacing: 10) {
            HStack {
                Picker("Select the chart type", selection: $chartType) {
                    ForEach(ChartType.allCases, id: \.rawValue) { value in
                        Image(systemName: value.rawValue)
                            .tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .onChange(of: chartType) { type in
                    chartDetent = type.detent
                }
                
                Spacer();
            }
            
            let moodsTotal = Statistics.shared.totalMoods(moods: moods)
            
            if chartType == .bar {
                Chart {
                    ForEach(Entry.colorsFromSadToHappy.indices, id: \.self) { mood in
                        BarMark(x: .value("Header", Entry.moodToHeader(mood: mood * 20)), y: .value("Value", moodsTotal[mood]))
                            .foregroundStyle(Entry.moodToColor(mood: mood * 20))
                    }
                }
                .frame(height: 250)
            } else if chartType == .pie {
                GeometryReader { geometry in
                    PieChartView(colors: Entry.colorsFromSadToHappy, titles: Entry.headersFromSadToHappy, values: moodsTotal.map { Double($0) }, width: 200)
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
        .background(Color.theme.background)
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
        let activitiesTotal = Statistics.shared.totalActivities(moods: moods)
        
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
                
                HStack(spacing: 15) {
                    ForEach(displayedActivitiesTotal.indices.reversed(), id: \.self) { index in
                        VStack(spacing: 15) {
                            ZStack(alignment: .bottom) {
                                Capsule()
                                    .fill(.bar)
                                    .frame(width: 20, height: 120)
                                Capsule()
                                    .fill(.linearGradient(colors: Utilities.gradient, startPoint: .top, endPoint: .bottom))
                                    .frame(width: 20, height: CGFloat(120 / most * displayedActivitiesTotal[index].1))
                            }
                            
                            Image(systemName: displayedActivitiesTotal[index].0.systemName!)
                                .foregroundLinearGradient(colors: Utilities.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
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
    @FetchRequest(sortDescriptors: []) private var appearances: FetchedResults<DailyAppearance>
    
    @State private var showMoods: Bool = true
    
    @State private var showDailyAppearance: Bool = false
    @State private var selectedDailyAppearance: DailyAppearance?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("This Year")
                    .font(.title)
                    .bold()
                
                Picker("", selection: $showMoods) {
                    Text("Moods")
                        .tag(true)
                    Text("Daily Challenges")
                        .tag(false)
                }
                .fixedSize()
                .pickerStyle(.menu)
                .accentColor(.secondary)
                
                Spacer()
            }
            
            let start = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Calendar.current.startOfDay(for: .now)))!
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
                        
                        let year = Calendar.current.component(.year, from: .now)
                        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Calendar.current.date(from: DateComponents(year: year, month: month))!)!.count
                        ForEach(1...daysInMonth, id: \.self) { day in
                            let dateComponents = DateComponents(year: year, month: month, day: day, hour: 0, minute: 0, second: 0)
                            let date = Calendar.current.date(from: dateComponents)!
                            
                            if showMoods {
                                let mood = date > .now ? nil : Statistics.shared.safeAverage(mood: moods[date]!)
                                let color: Color = mood == nil ? .secondary : Entry.moodToColor(mood: Int(mood!))
                                
                                Circle()
                                    .fill(color)
                                    .frame(width: 13, height: 13)
                            } else {
                                let appearance = context.dailyAppearance(from: date)
                                let color: LinearGradient = appearance == nil ? .linearGradient(colors: [.secondary], startPoint: .topLeading, endPoint: .bottomTrailing) : .linearGradient(colors: Utilities.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                
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
            
            Divider()
            
            let moodsTotal = Statistics.shared.totalMoods(moods: moods)

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
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(20)
        .sheet(isPresented: $showDailyAppearance) {
            DailyAppearanceView(appearance: $selectedDailyAppearance)
        }
    }
}

// visualizes the user's information
struct StatsView: View {
    @StateObject var viewRouter: ViewRouter
    
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]) private var entries: FetchedResults<Entry>
    
    @State private var chartDetent: PresentationDetent = ChartType.bar.detent
    
    @State private var showMoodGraph: Bool = false
    @State private var showTotalMoodsChart: Bool = false
        
    var body: some View {
        if entries.isEmpty {
            Text("Not enough data yet to display statistics...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                Picker("Select the range of entries", selection: $viewRouter.statsViewDayRange) {
                    ForEach(DayRangeType.allCases, id: \.rawValue) { value in
                        Text(value.rawValue)
                            .tag(value)
                    }
                }
                .pickerStyle(.segmented)
                
                let days = 15
                let moods = entries.lastMoods(dayRange: days)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Mood Graph")
                            .font(.title)
                            .bold()
                        
                        Text("Tap to expand")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    let gradient: [Color] = [.white, .accentColor]
                    Chart {
                        ForEach(Array(moods.keys).sorted(by: { $0.compare($1) == .orderedAscending }), id: \.self) { key in
                            let y = Statistics.shared.safeAverage(mood: moods[key]!)
                            if y != nil {
                                let weekDayFormatted = key.formatted(Date.FormatStyle().weekday(.abbreviated))
                                LineMark(x: .value("Day", "\(weekDayFormatted) \(Time.shared.getMonthDay(from: key))"), y: .value("Value", y!))
                                    .foregroundStyle(Color.accentColor)
                                    .interpolationMethod(.catmullRom)
                                AreaMark(x: .value("Day", "\(weekDayFormatted) \(Time.shared.getMonthDay(from: key))"), y: .value("Value", y!))
                                    .foregroundStyle(.linearGradient(colors: gradient.enumerated().map { (index, color) in
                                        return color.opacity(Double(index) / 2.0)
                                    }, startPoint: .bottom, endPoint: .top))
                                    .interpolationMethod(.catmullRom)
                            }
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYScale(domain: 0...100)
                    .frame(height: 150)
                }
                .padding()
                .background(Color.theme.secondaryBackground)
                .cornerRadius(20)
                .padding()
                .onTapGesture {
                    showMoodGraph = true
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Total Moods Chart")
                            .font(.title)
                            .bold()
                        
                        Text("Tap to expand")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    let moodsTotal = Statistics.shared.totalMoods(moods: moods)

                    Chart {
                        ForEach(Entry.colorsFromSadToHappy.indices, id: \.self) { mood in
                            BarMark(x: .value("Header", Entry.moodToHeader(mood: mood * 20)), y: .value("Value", moodsTotal[mood]))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: 150)
                }
                .padding()
                .background(Color.theme.secondaryBackground)
                .cornerRadius(20)
                .padding()
                .onTapGesture {
                    showTotalMoodsChart = true
                }
                
                TotalActivitiesChart(viewRouter: viewRouter)
                    .padding()
                                    
                YearView(viewRouter: viewRouter)
                    .environment(\.managedObjectContext, context)
                    .padding()
                
                MakeSpaceForTabBar()
            }
            .background(Color.theme.background)
            .sheet(isPresented: $showMoodGraph) {
                MoodGraphView(viewRouter: viewRouter)
                    .presentationDetents([.medium, .fraction(0.4)])
            }
            .sheet(isPresented: $showTotalMoodsChart) {
                TotalMoodsChart(viewRouter: viewRouter, chartDetent: $chartDetent)
                    .presentationDetents([chartDetent], selection: $chartDetent)
                    .onDisappear {
                        chartDetent = ChartType.bar.detent
                    }
            }
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
