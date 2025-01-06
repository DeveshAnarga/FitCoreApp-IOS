//  CaloriesViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 20/5/2024.
//
/*
 This view controller is responsible for displaying the user's daily step count and the corresponding calories burned.
 It integrates with HealthKit to fetch and observe step count data. The UI includes labels to display the total calories burned,
 the current step count, and a progress view that visually represents the progress towards a daily calorie goal. The controller
 also includes a method to calculate calories based on the step count.
*/

import UIKit
import Charts
import DGCharts
import HealthKit

class CaloriesViewController: UIViewController {
    
    let healthKitManager = HealthKitManager.shared
    var stepCount = 0.0
    var caloriesBurned = 0.0
    
    // UI Elements
    var totalCaloriesLabel: UILabel!
    var stepsLabel: UILabel!
    var caloriesProgressView: UIProgressView!
    var progressGoalLabel: UILabel!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        startObservingSteps()
        fetchTodaySteps()
    }
    
    // MARK: - Setup UI
    // This function sets up the user interface elements.
    func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.text = "Total Cal's Burnt"
        view.addSubview(titleLabel)
        
        // Total Calories Label
        totalCaloriesLabel = UILabel()
        totalCaloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        totalCaloriesLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        totalCaloriesLabel.textAlignment = .center
        totalCaloriesLabel.textColor = .systemBlue
        view.addSubview(totalCaloriesLabel)
        
        // Steps Label
        stepsLabel = UILabel()
        stepsLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        stepsLabel.textAlignment = .center
        stepsLabel.textColor = .label
        view.addSubview(stepsLabel)
        
        // Progress View
        caloriesProgressView = UIProgressView(progressViewStyle: .default)
        caloriesProgressView.translatesAutoresizingMaskIntoConstraints = false
        caloriesProgressView.trackTintColor = .systemGray4
        caloriesProgressView.progressTintColor = .systemBlue
        caloriesProgressView.layer.cornerRadius = 8
        caloriesProgressView.clipsToBounds = true
        view.addSubview(caloriesProgressView)
        
        // Progress Goal Label
        progressGoalLabel = UILabel()
        progressGoalLabel.translatesAutoresizingMaskIntoConstraints = false
        progressGoalLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        progressGoalLabel.textAlignment = .center
        progressGoalLabel.textColor = .label
        progressGoalLabel.text = "Goal: 1000 Calories"
        view.addSubview(progressGoalLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            totalCaloriesLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            totalCaloriesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stepsLabel.topAnchor.constraint(equalTo: totalCaloriesLabel.bottomAnchor, constant: 20),
            stepsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            caloriesProgressView.topAnchor.constraint(equalTo: stepsLabel.bottomAnchor, constant: 40),
            caloriesProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            caloriesProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            caloriesProgressView.heightAnchor.constraint(equalToConstant: 20),
            
            progressGoalLabel.topAnchor.constraint(equalTo: caloriesProgressView.bottomAnchor, constant: 10),
            progressGoalLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    // MARK: - Start Observing Steps
    // This function starts observing step count changes using HealthKit.
    func startObservingSteps() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        healthKitManager.requestAuthorization { [weak self] success, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error requesting HealthKit authorization: \(error.localizedDescription)")
                return
            }
            
            if success {
                self.healthKitManager.observeStepCountChanges { steps in
                    DispatchQueue.main.async {
                        self.stepCount = steps
                        self.calculateCalories()
                        self.updateUI()
                    }
                }
            } else {
                print("HealthKit authorization denied!")
            }
        }
    }
    
    // MARK: - Fetch Today's Steps
    // This function fetches the step count for today using HealthKit.
    func fetchTodaySteps() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        healthKitManager.fetchSteps(for: Date()) { [weak self] steps in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.stepCount = steps
                self.calculateCalories()
                self.updateUI()
            }
        }
    }
    
    // MARK: - Calculate Calories
    // This function calculates the calories burned based on the step count.
    func calculateCalories() {
        // Assuming an average burn rate of 0.04 calories per step
        self.caloriesBurned = stepCount * 0.04
    }
    
    // MARK: - Update UI
    // This function updates the UI with the latest step count and calories burned.
    func updateUI() {
        totalCaloriesLabel.text = String(format: "%.2f Calories", caloriesBurned)
        stepsLabel.text = "Current Steps: \(Int(stepCount))"
        
        // Assuming a daily goal of 1000 calories for progress view
        let progress = Float(caloriesBurned / 1000.0)
        caloriesProgressView.setProgress(progress, animated: true)
    }
}

/*
   References:
   - Apple Developer Documentation - HealthKit: [HealthKit](https://developer.apple.com/documentation/healthkit)
   - Apple Developer Documentation - HKHealthStore: [HKHealthStore](https://developer.apple.com/documentation/healthkit/hkhealthstore)
   - Apple Developer Documentation - UILabel: [UILabel](https://developer.apple.com/documentation/uikit/uilabel)
   - Apple Developer Documentation - UIProgressView: [UIProgressView](https://developer.apple.com/documentation/uikit/uiprogressview)
   - Stack Overflow - Working with HealthKit: [Stack Overflow](https://stackoverflow.com/questions/27094477/working-with-healthkit)
   - YouTube - HealthKit Tutorial for Beginners: [YouTube](https://www.youtube.com/watch?v=h2t0OzT6c0E)
   - Medium - Integrating HealthKit with iOS Apps: [Medium](https://medium.com/@felixdumit/ios-healthkit-basics-swift-4-18cd16d74c69)
   - Ray Wenderlich - HealthKit Tutorial with Swift: [Ray Wenderlich](https://www.raywenderlich.com/459-healthkit-tutorial-with-swift-getting-started)
   - Apple Developer Documentation - Auto Layout: [Auto Layout](https://developer.apple.com/documentation/uikit/nslayoutconstraint)
   - YouTube - iOS Auto Layout Tutorial: [YouTube](https://www.youtube.com/watch?v=G7KSHf3RtZ8)
*/

