//
//  HealthKitManager.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 18/5/2024.

//HealthKitManager is a singleton class responsible for managing interactions with the HealthKit framework. It provides methods for requesting user authorization, fetching step count data, observing step count changes, and starting step count queries. This class encapsulates HealthKit-related functionalities to ensure a centralized and organized approach to accessing health data.

import HealthKit

class HealthKitManager {
    
    // MARK: - Properties
    
    // Singleton instance of HealthKitManager
    static let shared = HealthKitManager()
    
    // HealthKit store for accessing health data
    let healthStore = HKHealthStore()
    
    // Anchor for tracking changes in step count
    private var anchor: HKQueryAnchor?
    
    // MARK: - Authorization
    
    /// Requests authorization to read step count data from HealthKit.
    /// - Parameter completion: A closure to be called upon completion of the authorization request, containing a boolean value indicating whether the request was successful and an optional error if any.
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Check if HealthKit is available on the device
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.yourapp.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        // Define the type of health data to read (step count)
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let typesToRead: Set = [stepType]
        
        // Request authorization to read step count data
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    // MARK: - Data Fetching
    
    /// Fetches the total step count for a specific date.
    /// - Parameters:
    ///   - date: The date for which step count data is to be fetched.
    ///   - completion: A closure to be called upon completion of the fetch operation, containing the total step count as a double value.
    func fetchSteps(for date: Date, completion: @escaping (Double) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        // Define the start and end of the day for the specified date
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Create a predicate to query step count samples for the specified date range
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        // Create a statistics query to calculate the cumulative sum of step counts
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        
        // Execute the query using the health store
        healthStore.execute(query)
    }
    
    /// Fetches the weekly step count data for the current week (Monday to Sunday).
    /// - Parameter completion: A closure to be called upon completion of the fetch operation, containing an array of step count data for each day of the week.
    func fetchWeeklySteps(completion: @escaping ([Double]) -> Void) {
        var stepsArray: [Double] = []
        let dispatchGroup = DispatchGroup()
        let calendar = Calendar.current
        
        // Calculate the start of the week (Monday)
        var startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        if calendar.component(.weekday, from: startOfWeek) != 2 { // Ensure startOfWeek is Monday
            startOfWeek = calendar.date(byAdding: .day, value: 2 - calendar.component(.weekday, from: startOfWeek), to: startOfWeek)!
        }
        
        // Fetch steps for each day of the week (Monday to Sunday)
        for i in 0..<7 {
            dispatchGroup.enter()
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            fetchSteps(for: date) { steps in
                stepsArray.append(steps)
                dispatchGroup.leave()
            }
        }
        
        // Notify completion when all fetch operations finish
        dispatchGroup.notify(queue: .main) {
            completion(stepsArray)
        }
    }
    
    // MARK: - Data Observation
    
    /// Observes changes in the step count and invokes the provided completion handler with the updated step count.
    /// - Parameter completion: A closure to be called whenever the step count changes, containing the updated step count as a double value.
    func observeStepCountChanges(completion: @escaping (Double) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        // Enable background delivery of step count updates
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success {
                // Create an observer query to monitor step count changes
                let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
                    if let error = error {
                        print("Observer query failed: \(error.localizedDescription)")
                        return
                    }
                    // Fetch the updated step count and invoke the completion handler
                    self?.fetchSteps(for: Date(), completion: completion)
                    completionHandler()
                }
                // Execute the observer query
                self.healthStore.execute(query)
            } else {
                print("Failed to enable background delivery for step count: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    /// Starts a continuous query for step count updates since the app launch.
    /// - Parameter completion: A closure to be called whenever the step count changes, containing the updated step count as a double value.
    func startStepCountQuery(completion: @escaping (Double) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        // Create a predicate to query all step count samples since the app launch
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        
        // Create an anchored object query to continuously monitor step count changes
        let query = HKAnchoredObjectQuery(type: stepType, predicate: predicate, anchor: anchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, error in
            guard error == nil, let newAnchor = newAnchor else {
                return
            }
            // Update the anchor and fetch the updated step count
            self?.anchor = newAnchor
            self?.fetchSteps(for: Date(), completion: completion)
        }
        
        // Configure the update handler to handle incremental changes
        query.updateHandler = { [weak self] _, samples, _, newAnchor, error in
            guard error == nil, let newAnchor = newAnchor else {
                return
            }
            // Update the anchor and fetch the updated step count
            self?.anchor = newAnchor
            self?.fetchSteps(for: Date(), completion: completion)
        }
        
        // Execute the anchored object query
        healthStore.execute(query)
    }
}


/*

References:
- Apple Developer Documentation - [HealthKit](https://developer.apple.com/documentation/healthkit) for integrating HealthKit into the app and managing health data.
- Apple Developer Documentation - [HKHealthStore](https://developer.apple.com/documentation/healthkit/hkhealthstore) for accessing and storing health data.
- Apple Developer Documentation - [HKQuantityType](https://developer.apple.com/documentation/healthkit/hkquantitytype) for representing types of health data, such as step count.
- Apple Developer Documentation - [HKStatisticsQuery](https://developer.apple.com/documentation/healthkit/hkstatisticsquery) for querying health data statistics, such as sum of step counts within a specific time range.
- Apple Developer Documentation - [HKObserverQuery](https://developer.apple.com/documentation/healthkit/hkobserverquery) for observing changes to health data, such as step count updates.
- Apple Developer Documentation - [HKAnchoredObjectQuery](https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery) for querying health data changes, such as new step count samples.
- Swift Documentation - [Singleton Design Pattern](https://developer.apple.com/documentation/swift/cocoa_design_patterns/managing_a_shared_resource_using_a_singleton) for implementing the singleton pattern.
*/
