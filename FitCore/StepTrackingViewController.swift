//  StepTrackingViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 18/5/2024.
//
/*
 This view controller tracks and displays the user's step count using HealthKit and visualizes the data using charts from the Charts library.
 It includes real-time step count observation, daily and weekly data fetching, and updates using a ring chart for daily steps and a bar chart for weekly steps.
*/

import UIKit
import HealthKit
import Charts
import DGCharts

class StepTrackingViewController: UIViewController {
    
    private let healthKitManager = HealthKitManager.shared
    private let ringChartView = PieChartView()
    private let barChartView = BarChartView()
    private let stepsLabel = UILabel()
    private let dailyStepsTitleLabel = UILabel()
    private let timeFrameSegmentedControl = UISegmentedControl(items: ["D", "W"])
    private var dailyUpdateTimer: Timer?
    private var weeklyUpdateTimer: Timer?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI() // Setup the UI components
        
        // Fetch real-time data from HealthKit
        observeStepCount()
        
        // Fetch initial data
        fetchHealthKitData(for: .day)
        
        // Schedule daily update for ring chart at 12:00 AM
        scheduleDailyUpdate()
        
        // Schedule weekly update for bar chart on Mondays at 1:00 AM
        scheduleWeeklyUpdate()
        
        // Set initial hole color based on the current user interface style
        updateRingChartHoleColor()
    }
    
    // MARK: - HealthKit Data Observing
    
    private func observeStepCount() {
        healthKitManager.requestAuthorization { [weak self] success, error in
            if success {
                self?.healthKitManager.observeStepCountChanges { steps in
                    DispatchQueue.main.async {
                        self?.stepsLabel.text = "Steps: \(Int(steps))"
                        self?.updateRingChart(steps: steps)
                    }
                }
                self?.healthKitManager.startStepCountQuery { steps in
                    DispatchQueue.main.async {
                        self?.stepsLabel.text = "Steps: \(Int(steps))"
                        self?.updateRingChart(steps: steps)
                    }
                }
            } else {
                print("HealthKit authorization denied!")
            }
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Steps Label
        stepsLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepsLabel.textAlignment = .center
        stepsLabel.textColor = .label
        stepsLabel.text = "Steps: 0"
        view.addSubview(stepsLabel)
        
        // Daily Steps Title Label
        dailyStepsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        dailyStepsTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        dailyStepsTitleLabel.textAlignment = .center
        dailyStepsTitleLabel.textColor = .label
        dailyStepsTitleLabel.text = "Today's Steps"
        view.addSubview(dailyStepsTitleLabel)
        
        // Time Frame Segmented Control
        timeFrameSegmentedControl.selectedSegmentIndex = 0
        timeFrameSegmentedControl.addTarget(self, action: #selector(timeFrameChanged), for: .valueChanged)
        timeFrameSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeFrameSegmentedControl)
        
        // Ring Chart View
        ringChartView.translatesAutoresizingMaskIntoConstraints = false
        ringChartView.chartDescription.enabled = false
        ringChartView.drawEntryLabelsEnabled = false
        ringChartView.drawHoleEnabled = true
        ringChartView.holeRadiusPercent = 0.8
        ringChartView.transparentCircleRadiusPercent = 0.85
        ringChartView.legend.enabled = false
        view.addSubview(ringChartView)
        
        // Bar Chart View
        barChartView.translatesAutoresizingMaskIntoConstraints = false
        barChartView.chartDescription.enabled = false
        barChartView.legend.enabled = false
        barChartView.xAxis.labelPosition = .bottom
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.drawGridLinesEnabled = false
        barChartView.rightAxis.enabled = false
        view.addSubview(barChartView)
        
        // Constraints
        NSLayoutConstraint.activate([
            stepsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            dailyStepsTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dailyStepsTitleLabel.topAnchor.constraint(equalTo: stepsLabel.bottomAnchor, constant: 20),
            
            timeFrameSegmentedControl.topAnchor.constraint(equalTo: dailyStepsTitleLabel.bottomAnchor, constant: 20),
            timeFrameSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            ringChartView.topAnchor.constraint(equalTo: timeFrameSegmentedControl.bottomAnchor, constant: 20),
            ringChartView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ringChartView.widthAnchor.constraint(equalToConstant: 200),
            ringChartView.heightAnchor.constraint(equalToConstant: 200),
            
            barChartView.topAnchor.constraint(equalTo: ringChartView.bottomAnchor, constant: 40),
            barChartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            barChartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            barChartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Time Frame Selection
    
    @objc private func timeFrameChanged() {
        let index = timeFrameSegmentedControl.selectedSegmentIndex
        let timeFrame: TimeFrame = TimeFrame(rawValue: index) ?? .day
        fetchHealthKitData(for: timeFrame)
    }
    
    // MARK: - Fetch HealthKit Data
    
    private func fetchHealthKitData(for timeFrame: TimeFrame) {
        healthKitManager.requestAuthorization { success, error in
            if success {
                switch timeFrame {
                case .day:
                    self.healthKitManager.fetchSteps(for: Date()) { steps in
                        DispatchQueue.main.async {
                            self.stepsLabel.text = "Steps: \(Int(steps))"
                            self.updateRingChart(steps: steps)
                            self.updateBarChart(stepsArray: [steps], labels: ["Today"])
                        }
                    }
                case .week:
                    self.healthKitManager.fetchWeeklySteps { stepsArray in
                        DispatchQueue.main.async {
                            let dateLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                            self.updateBarChart(stepsArray: stepsArray, labels: dateLabels)
                        }
                    }
                }
            } else {
                print("HealthKit authorization denied!")
            }
        }
    }
    
    // MARK: - Update Charts
    
    private func updateRingChart(steps: Double) {
        let remainingSteps = max(0, 10000 - steps)
        let entry1 = PieChartDataEntry(value: steps, label: "Completed Steps")
        let entry2 = PieChartDataEntry(value: remainingSteps, label: "Remaining Steps")
        
        let dataSet = PieChartDataSet(entries: [entry1, entry2], label: "")
        dataSet.colors = [.systemPink, .systemTeal]
        
        let data = PieChartData(dataSet: dataSet)
        ringChartView.data = data
    }
    
    private func updateBarChart(stepsArray: [Double], labels: [String]) {
        var entries: [BarChartDataEntry] = []
        
        for (index, steps) in stepsArray.enumerated() {
            let entry = BarChartDataEntry(x: Double(index), y: steps)
            entries.append(entry)
        }
        
        let dataSet = BarChartDataSet(entries: entries, label: "")
        dataSet.colors = [.systemGreen]
        
        let data = BarChartData(dataSet: dataSet)
        barChartView.data = data
        
        let xAxis = barChartView.xAxis
        xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        xAxis.granularity = 1
    }
    
    // MARK: - Schedule Updates
    
    private func scheduleDailyUpdate() {
        let calendar = Calendar.current
        if let tomorrowMidnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date().addingTimeInterval(24 * 60 * 60)) {
            let timeInterval = tomorrowMidnight.timeIntervalSinceNow
            dailyUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                self?.resetData()
                self?.fetchHealthKitData(for: .day)
                self?.scheduleDailyUpdate()
            }
        }
    }
    
    // This function schedules a weekly update to fetch and display the step count data.
    private func scheduleWeeklyUpdate() {
        let calendar = Calendar.current
        // Find the next occurrence of Monday after the current date.
        if let nextMonday = calendar.nextDate(after: Date(), matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) {
            // Set the date and time to 1:00 AM on the next Monday.
            let nextMonday1AM = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: nextMonday)!
            // Calculate the time interval between now and the next Monday at 1:00 AM.
            let timeInterval = nextMonday1AM.timeIntervalSinceNow
            // Schedule a timer to trigger the weekly update.
            weeklyUpdateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                // Reset the step count and chart data.
                self?.resetData()
                // Fetch the HealthKit data for the week.
                self?.fetchHealthKitData(for: .week)
                // Schedule the next weekly update.
                self?.scheduleWeeklyUpdate()
            }
        }
    }
    
    // This function resets the displayed data.
    private func resetData() {
        self.stepsLabel.text = "Steps: 0"
        self.ringChartView.data = nil
        self.barChartView.data = nil
    }
    
    // This function updates the hole color of the ring chart based on the current user interface style.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateRingChartHoleColor()
    }
    
    // This function sets the hole color of the ring chart to match the current user interface style.
    private func updateRingChartHoleColor() {
        if traitCollection.userInterfaceStyle == .dark {
            ringChartView.holeColor = .black
        } else {
            ringChartView.holeColor = .white
        }
    }
    
    // This function invalidates the timers to prevent memory leaks.
    deinit {
        dailyUpdateTimer?.invalidate()
        weeklyUpdateTimer?.invalidate()
    }
    
    // Enumeration for time frames (day and week) with corresponding date components.
    private enum TimeFrame: Int {
        case day = 0, week
        
        var dateComponents: DateComponents {
            switch self {
            case .day:
                return DateComponents(day: -6)
            case .week:
                return DateComponents(day: -6)
            }
        }
    }
    
}

    /*
       References:
       - Apple Developer Documentation - Timer: [Timer](https://developer.apple.com/documentation/foundation/timer)
       - Apple Developer Documentation - Calendar: [Calendar](https://developer.apple.com/documentation/foundation/calendar)
       - Apple Developer Documentation - DateComponents: [DateComponents](https://developer.apple.com/documentation/foundation/datecomponents)
       - Apple Developer Documentation - HealthKit: [HealthKit](https://developer.apple.com/documentation/healthkit)
       - Apple Developer Documentation - Charts: [Charts](https://developer.apple.com/documentation/charts)
       - YouTube - Using HealthKit in iOS: [YouTube](https://www.youtube.com/watch?v=F6qO3g1I8aU)
       - Stack Overflow - Scheduling Timers: [Stack Overflow](https://stackoverflow.com/questions/24134522/scheduling-a-timer-in-swift)
    */
