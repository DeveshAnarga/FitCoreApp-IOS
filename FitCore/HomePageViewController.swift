//
//  HomePageViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 29/4/2024.
//HomePageViewController is a UIViewController subclass responsible for managing the main screen of the FitCore app. It allows users to track their consumed and remaining calories for the day, input calorie information for meals, view a pie chart representing their calorie consumption, and receive notifications for daily calorie resets. Additionally, it retrieves user profile data and calculates total daily calorie requirements based on user characteristics.

import UIKit
import FirebaseFirestoreSwift
import Firebase
import FirebaseAuth
import FirebaseDatabase
import DGCharts
import Charts
import SystemConfiguration
import UserNotifications




class HomePageViewController: UIViewController {
    
    
    // MARK: - Properties
    
    // API key for accessing external services.
    var apiKey: String?
    // Activity indicator to show loading state.
    var activityIndicator: UIActivityIndicatorView!
    // Timer to trigger tasks at midnight, like resetting daily data.
    var midnightTimer: Timer?
    
    
    // Outlet for the pie chart view displaying calorie consumption.
    @IBOutlet weak var pieChartView: PieChartView!
    // Total calorie limit for the day.
    var totalCalories: Double = 0
    // Total calories consumed by the user.
    var consumedCalories: Double = 0 {
        didSet {
            // Update labels showing consumed and remaining calories.
            consumedCaloriesLabel.text = "Consumed: \(Int(consumedCalories)) calories"
            remainingCaloriesLabel.text = "Remaining: \(Int(max(0, totalCalories - consumedCalories))) calories"
        }
    }
    // Label displaying the consumed calories.
    var consumedCaloriesLabel: UILabel!
    
    // Label displaying the remaining calories.
    var remainingCaloriesLabel: UILabel!
    
    
    
    
    // MARK: - Meal Actions
    
    
    // Action triggered when the breakfast button is tapped.
    @IBAction func breakFastTapped(_ sender: UIButton) {
        showCaloriesInputPopup(mealType: "Breakfast")
    }
    
    // Action triggered when the lunch button is tapped.
    @IBAction func lunchTapped(_ sender: UIButton) {
        showCaloriesInputPopup(mealType: "Lunch")
    }
    
    // Action triggered when the dinner button is tapped.
    @IBAction func dinnerTapped(_ sender: UIButton) {
        showCaloriesInputPopup(mealType: "Dinner")
        
    }
    
    // Edamam API Application ID used for food data retrieval.
    let edamamAppId = "4621b92b"
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the API key for external services.
        self.apiKey = "8517e4a8814bf6216dea106329872817"
        
        // Initialize consumed and remaining calories labels.
        consumedCaloriesLabel = createLabel(withText: "Consumed: 0 calories")
        remainingCaloriesLabel = createLabel(withText: "Remaining: \(Int(totalCalories)) calories")
        
        // Set up constraints for consumed and remaining calories labels.
        NSLayoutConstraint.activate([
            consumedCaloriesLabel.centerXAnchor.constraint(equalTo: pieChartView.centerXAnchor),
            consumedCaloriesLabel.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 20)
        ])
        
        NSLayoutConstraint.activate([
            remainingCaloriesLabel.centerXAnchor.constraint(equalTo: pieChartView.centerXAnchor),
            remainingCaloriesLabel.topAnchor.constraint(equalTo: consumedCaloriesLabel.bottomAnchor, constant: 10)
        ])
        
        // Initialize and configure the activity indicator.
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // Set up constraints for the activity indicator.
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Check network connectivity status.
        checkNetworkConnectivity()
        
        // Update the color of the pie chart hole.
        updatePieChartHoleColor()
        
        // Add observers for app lifecycle events and user profile updates.
        NotificationCenter.default.addObserver(self, selector: #selector(checkDayReset), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userProfileUpdated), name: Notification.Name("UserProfileUpdated"), object: nil)
        
        // Request notification permissions for the app.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied: \(error)")
            }
        }
        
        // Schedule the midnight check for resetting daily data.
        scheduleMidnightCheck()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Check if a user is logged in and retrieve user profile and calorie data from Realtime Database.
        if let userID = Auth.auth().currentUser?.uid {
            retrieveUserProfile(userID: userID)
            retrieveCalorieDataFromRealtimeDB(userID: userID)
        } else {
            print("Error: No logged-in user")
        }
    }
    
    // Method triggered when the user profile is updated.
    @objc func userProfileUpdated() {
        // Retrieve user profile and calorie data from Realtime Database for the current user.
        if let userID = Auth.auth().currentUser?.uid {
            retrieveUserProfile(userID: userID)
            retrieveCalorieDataFromRealtimeDB(userID: userID)
        }
    }
    
    // Retrieve calorie data from Realtime Database for the specified user ID.
    func retrieveCalorieDataFromRealtimeDB(userID: String) {
        let ref = Database.database().reference().child("users").child(userID)
        
        // Observe a single event to retrieve calorie data from Realtime Database.
        ref.observeSingleEvent(of: .value) { snapshot in
            // Check if the snapshot exists and contains valid data.
            guard snapshot.exists(), let calorieData = snapshot.value as? [String: Any] else {
                print("Error: Failed to retrieve calorie data from Realtime Database")
                return
            }
            
            // Extract consumed calories from the snapshot data and update the UI.
            if let consumedCalories = calorieData["consumedCalories"] as? Double {
                self.consumedCalories = consumedCalories
                self.updatePieChart()
            } else {
                print("Error: Calorie data format is incorrect")
            }
        }
    }
    
    // Save consumed calories data to Realtime Database.
    func saveConsumedCaloriesToRealtimeDB() {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("users").child(userID)
        
        // Create a dictionary to represent calorie data.
        let calorieData = [
            "consumedCalories": consumedCalories
        ]
        
        // Write the calorie data to Realtime Database.
        ref.setValue(calorieData) { error, _ in
            if let error = error {
                print("Error writing data to Realtime Database: \(error)")
            } else {
                print("Calorie data successfully saved to Realtime Database")
            }
        }
    }
    
    // Function to set up the UI elements, including the pie chart.
    private func setupUI() {
        // Configure the pie chart view
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        pieChartView.chartDescription.enabled = false
        pieChartView.drawEntryLabelsEnabled = false
        pieChartView.drawHoleEnabled = true
        pieChartView.holeRadiusPercent = 0.5
        pieChartView.transparentCircleRadiusPercent = 0.6
        pieChartView.legend.enabled = false
        view.addSubview(pieChartView)
        
        // Update the hole color of the pie chart based on the current user interface style
        updatePieChartHoleColor()
        
        // Add layout constraints to position and size the pie chart view
        NSLayoutConstraint.activate([
            pieChartView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pieChartView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            pieChartView.widthAnchor.constraint(equalToConstant: 250),
            pieChartView.heightAnchor.constraint(equalToConstant: 250)
        ])
    }
    
    // Function to update the data displayed in the pie chart.
    private func updatePieChart() {
        // Calculate the remaining calories
        let remainingCalories = max(0, totalCalories - consumedCalories)
        
        // Create data entries for consumed and remaining calories
        let entry1 = PieChartDataEntry(value: Double(consumedCalories), label: "Consumed")
        let entry2 = PieChartDataEntry(value: Double(remainingCalories), label: "Remaining")
        
        // Define colors for the data set
        let brightOrangeColor = UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1.0)
        let luminousPinkMixedPurpleOrange = UIColor(red: 255/255, green: 20/255, blue: 147/255, alpha: 1.0)
        
        // Create a data set with the entries and colors
        let dataSet = PieChartDataSet(entries: [entry1, entry2], label: "")
        dataSet.colors = [brightOrangeColor, luminousPinkMixedPurpleOrange]
        dataSet.selectionShift = 5
        dataSet.sliceSpace = 2
        
        // Create chart data with the data set
        let data = PieChartData(dataSet: dataSet)
        pieChartView.data = data
        
        // Animate the chart
        pieChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .easeInOutQuart)
    }
    
    // Function to update the hole color of the pie chart based on the current user interface style.
    private func updatePieChartHoleColor() {
        // Set the hole color of the pie chart based on the current user interface style
        if traitCollection.userInterfaceStyle == .dark {
            pieChartView.holeColor = .black
        } else {
            pieChartView.holeColor = .white
        }
    }
    
    // Function called when the user interface style changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Update the hole color of the pie chart when the user interface style changes
        updatePieChartHoleColor()
    }
    
    // Method to check for the day reset at midnight and send a local notification.
    @objc func checkDayReset() {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        let currentMinute = calendar.component(.minute, from: Date())
        
        // Check if it's midnight in the current time zone
        if currentHour == 0 && currentMinute == 0 {
            // Reset consumed calories at midnight
            resetCaloriesAtMidnight()
        } else {
            // Retrieve calorie data from Realtime Database for the current user
            retrieveCalorieDataFromRealtimeDB(userID: Auth.auth().currentUser?.uid ?? "")
        }
    }
    
    // Function to schedule a recurring check for the day reset at midnight.
    private func scheduleMidnightCheck() {
        // Invalidate any existing timer
        midnightTimer?.invalidate()
        
        // Schedule a repeating timer to check every minute
        midnightTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(checkDayReset), userInfo: nil, repeats: true)
        
        // Ensure the timer runs on the main thread
        RunLoop.main.add(midnightTimer!, forMode: .common)
        
        // Set up a local notification to reset calories at midnight
        var dateComponents = DateComponents()
        dateComponents.hour = 0
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Calorie Reset"
        content.body = "Your daily calorie count has been reset."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "MidnightCalorieReset", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // Function to reset consumed calories at midnight.
    @objc func resetCaloriesAtMidnight() {
        // Reset consumed calories to zero and save the changes to Realtime Database
        consumedCalories = 0
        saveConsumedCaloriesToRealtimeDB()
        // Update the pie chart to reflect the changes
        updatePieChart()
    }
    
    // Deinitializer to clean up resources and remove observers.
    deinit {
        // Invalidate the midnight timer and remove observers
        midnightTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // Private function to create a UILabel with specified text.
    private func createLabel(withText text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = text
        label.textColor = .label
        view.addSubview(label)
        return label
    }
    
    // Function to check network connectivity and display an alert if there's no internet connection.
    func checkNetworkConnectivity() {
        if !isConnectedToNetwork() {
            let alert = UIAlertController(title: "No Internet Connection",
                                          message: "Please check your internet connection and try again.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // Function to check if the device is connected to a network.
    func isConnectedToNetwork() -> Bool {
        // Prepare a sockaddr_in struct with zero values for IP and port
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        // Create a SCNetworkReachabilityRef object with the zeroAddress
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        // Get the network reachability flags
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        // Check if the device is reachable and if a connection is required
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    // Function to retrieve user profile data from Realtime Database.
    func retrieveUserProfile(userID: String) {
        let ref = Database.database().reference().child("userProfiles").child(userID)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists(), let userData = snapshot.value as? [String: String] else {
                print("Error: Failed to retrieve user profile data")
                return
            }
            
            // Print retrieved user profile data for debugging purposes
            print("User Profile Data:", userData)
            
            // Create a UserProfile object from the retrieved data
            let userProfile = UserProfile(dateOfBirth: userData["dateOfBirth"] ?? "",
                                          gender: userData["gender"] ?? "",
                                          height: userData["height"] ?? "",
                                          weight: userData["weight"] ?? "",
                                          activityLevel: userData["activityLevel"] ?? "")
            
            // Print the created UserProfile object for debugging purposes
            print("User Profile:", userProfile)
            
            // Calculate and set remaining calories based on the user profile
            self.calculateAndSetRemainingCalories(userProfile: userProfile)
        }
    }
    
    // Function to calculate and set the remaining calories based on the user's profile.
    func calculateAndSetRemainingCalories(userProfile: UserProfile) {
        // Calculate the age from the date of birth
        let age = calculateAge(from: userProfile.dateOfBirth ?? "2000-01-01")
        
        // Print user profile data before calculating total calories for debugging purposes
        print("User Profile Data before calculating total calories: height: \(userProfile.height), weight: \(userProfile.weight), age: \(age), gender: \(userProfile.gender), activityLevel: \(userProfile.activityLevel)")
        
        // Calculate the total calories based on the user profile and age
        let totalCalories = calculateTotalCalories(userProfile: userProfile, age: age)
        
        // Set the total calories and update the pie chart
        self.totalCalories = totalCalories
        updatePieChart()
    }
    
    // Function to calculate the total daily calories needed based on the user's profile.
    func calculateTotalCalories(userProfile: UserProfile, age: Int?) -> Double {
        guard let heightString = userProfile.height,
              let heightValue = parseMeasurement(heightString),
              let weightString = userProfile.weight,
              let weightValue = parseMeasurement(weightString),
              let age = age,
              let genderString = userProfile.gender,
              let activityLevelString = userProfile.activityLevel else {
            print("Error: Missing user profile data")
            return 2000 // Default value for total calories
        }
        
        // Calculate Basal Metabolic Rate (BMR) based on gender
        var bmr: Double = 0
        if genderString.lowercased() == "male" {
            bmr = 10 * weightValue + 6.25 * heightValue - 5 * Double(age) + 5
        } else {
            bmr = 10 * weightValue + 6.25 * heightValue - 5 * Double(age) - 161
        }
        
        // Determine the activity multiplier based on activity level
        var activityMultiplier: Double = 0
        switch activityLevelString.lowercased() {
        case "Not active":
            activityMultiplier = 1.2
        case "Moderately active":
            activityMultiplier = 1.55
        case "Extremely active":
            activityMultiplier = 1.9
        default:
            activityMultiplier = 1.0
        }
        
        // Calculate the total daily calories needed
        let totalCalories = bmr * activityMultiplier
        return totalCalories
    }
    
    
    // Function to parse a measurement string and extract the numeric value.
    func parseMeasurement(_ measurement: String) -> Double? {
        // Remove non-numeric characters from the measurement string
        let numericString = measurement.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        // Convert the numeric string to a Double
        return Double(numericString)
    }
    
    // Function to calculate age based on the provided date of birth.
    func calculateAge(from dateString: String) -> Int? {
        // Create a date formatter with the specified date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        // Attempt to convert the date string to a Date object
        if let dateOfBirth = dateFormatter.date(from: dateString) {
            // Get the current calendar
            let calendar = Calendar.current
            // Calculate the difference in years between the date of birth and the current date
            let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
            let age = ageComponents.year
            // Print the calculated age for debugging purposes
            print("Calculated age:", age ?? "Unknown")
            return age
        }
        return nil
    }
    
    // Function to display a calories input popup based on the meal type.
    func showCaloriesInputPopup(mealType: String) {
        // Check if consumed calories exceed total calories for today
        guard consumedCalories < totalCalories else {
            showAlert(message: "You have consumed all your allowed calories for today.")
            return
        }
        
        // Create and present an alert controller for entering calories
        let alertController = UIAlertController(title: "\(mealType) Calories", message: "Select an option:", preferredStyle: .alert)
        
        let enterManuallyAction = UIAlertAction(title: "Enter Manually", style: .default) { [weak self] _ in
            self?.showManualCaloriesInputAlert(mealType: mealType)
        }
        
        let nutritionPageAction = UIAlertAction(title: "Check Nutrition Page", style: .default) { [weak self] _ in
            self?.performSegue(withIdentifier: "Breaky", sender: nil)
        }
        
        let enterAndCheckAction = UIAlertAction(title: "Enter & Check Nutrition", style: .default) { [weak self] _ in
            self?.showFoodNameInputAlert(mealType: mealType)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(enterManuallyAction)
        alertController.addAction(nutritionPageAction)
        alertController.addAction(enterAndCheckAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Function to display an alert for manually entering calories.
    func showManualCaloriesInputAlert(mealType: String) {
        // Create an alert controller for entering calories manually
        let alertController = UIAlertController(title: "\(mealType) Calories", message: "Enter total \(mealType) calories:", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Total calories"
            textField.keyboardType = .numberPad
        }
        
        // Add actions for adding calories or canceling
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first,
                  let caloriesText = textField.text,
                  let calories = Double(caloriesText)
            else { return }
            
            // Ensure entered calories do not exceed remaining calories for today
            let remainingCalories = max(0, (self?.totalCalories ?? 2000) - (self?.consumedCalories ?? 0))
            guard calories <= remainingCalories else {
                self?.showAlert(message: "You cannot enter more calories than the remaining amount for today (\(Int(remainingCalories)) calories).")
                return
            }
            
            // Add consumed calories and update UI
            self?.addConsumedCalories(mealType: mealType, calories: calories)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Function to display an alert for entering food name.
    func showFoodNameInputAlert(mealType: String) {
        // Create an alert controller for entering food name
        let alertController = UIAlertController(title: "Enter Food Name", message: "Enter the name of the food:", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Food Name"
        }
        
        // Add actions for searching food or canceling
        let addAction = UIAlertAction(title: "Search", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first,
                  let foodName = textField.text,
                  !foodName.isEmpty
            else {
                self?.showAlert(message: "Please enter a valid food name.")
                return
            }
            
            // Search for food and add calories
            self?.searchFoodAndAddCalories(mealType: mealType, foodName: foodName)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Function to search for food and add calories based on food name.
      func searchFoodAndAddCalories(mealType: String, foodName: String) {
          // Start activity indicator animation
          activityIndicator.startAnimating()
          
          // Check if API key is available
          guard let apiKey = self.apiKey else {
              print("API key is missing.")
              return
          }
          
          // Encode food name and construct API URL
          guard let encodedQuery = foodName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                let url = URL(string: "https://api.edamam.com/api/food-database/v2/parser?ingr=\(encodedQuery)&app_id=\(edamamAppId)&app_key=\(apiKey)") else {
              print("Invalid URL")
              activityIndicator.stopAnimating()
              return
          }
          
          URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
              // Ensure self is still in memory
              guard let self = self else { return }
              
              // Perform UI updates on the main thread
              defer {
                  DispatchQueue.main.async {
                      self.activityIndicator.stopAnimating()
                  }
              }
              
              if let error = error {
                  // Handle network error
                  print("Error: \(error)")
                  return
              }
              
              guard let data = data else {
                  // Handle missing data
                  print("No data received")
                  return
              }
              
              do {
                  // Decode JSON response
                  let decoder = JSONDecoder()
                  let searchResponse = try decoder.decode(EdamamSearchResponse.self, from: data)
                  
                  if let food = searchResponse.hints.first?.food {
                      if let energy = food.nutrients.ENERC_KCAL {
                          // Add consumed calories to the total
                          DispatchQueue.main.async {
                              self.addConsumedCalories(mealType: mealType, calories: Double(energy))
                          }
                      } else {
                          // Show alert if calories information is not available
                          DispatchQueue.main.async {
                              self.showAlert(message: "Calories information not available for \(foodName).")
                          }
                      }
                  } else {
                      // Show alert if no matching food found
                      DispatchQueue.main.async {
                          self.showAlert(message: "No matching food found for \(foodName).")
                      }
                  }
              } catch {
                  // Handle JSON decoding error
                  print("Error decoding JSON: \(error)")
              }
          }.resume()
      }
      
      // Function to add consumed calories for the specified meal type
      func addConsumedCalories(mealType: String, calories: Double) {
          // Check if adding calories exceeds total calories for today
          guard (consumedCalories + calories) <= totalCalories else {
              showAlert(message: "You have consumed all your allowed calories for today.")
              return
          }
          
          // Update consumed calories and save to Realtime Database
          consumedCalories += calories
          updatePieChart()
          saveConsumedCaloriesToRealtimeDB()
      }
      
      // Function to update consumed calorie data in Realtime Database
      func updateCalorieDataInRealtimeDB(consumedCalories: Double) {
          guard let userID = Auth.auth().currentUser?.uid else {
              return
          }
          
          let ref = Database.database().reference().child("users").child(userID)
          
          let calorieData = [
              "consumedCalories": consumedCalories
          ]
          
          ref.setValue(calorieData) { error, _ in
              if let error = error {
                  print("Error updating data in Realtime Database: \(error)")
              } else {
                  print("Calorie data successfully updated in Realtime Database")
              }
          }
      }
      
      // Function to display an alert message
      func showAlert(message: String) {
          let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
          present(alertController, animated: true, completion: nil)
      }
  }


/*
   References:
   - Firebase documentation: https://firebase.google.com/docs/database
   - Stack Overflow for Firebase Realtime Database questions: https://stackoverflow.com/questions/tagged/firebase-realtime-database
   - Charts documentation: https://github.com/danielgindi/Charts
   - Stack Overflow for Charts questions: https://stackoverflow.com/questions/tagged/ios-charts
   - Apple's UIKit documentation: https://developer.apple.com/documentation/uikit
   - Ray Wenderlich tutorials: https://www.raywenderlich.com/uikit
   - Apple's User Notifications framework documentation: https://developer.apple.com/documentation/usernotifications
   - Ray Wenderlich tutorials on notifications: https://www.raywenderlich.com/5365-ios-notifications-getting-started
   - Apple's URLSession documentation: https://developer.apple.com/documentation/foundation/urlsession
   - Ray Wenderlich tutorials on networking: https://www.raywenderlich.com/3244963-urlsession-tutorial-getting-started
   - Apple's JSONSerialization documentation: https://developer.apple.com/documentation/foundation/jsonserialization
   - Swift by Sundell article on JSON parsing: https://www.swiftbysundell.com/articles/constructing-models-in-swift/
   - UIKit documentation for UIActivityIndicatorView: https://developer.apple.com/documentation/uikit/uiactivityindicatorview
   - Stack Overflow for UIActivityIndicatorView questions: https://stackoverflow.com/questions/tagged/uiactivityindicatorview
*/

