//
//  SettingsINTPageViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 24/4/2024.
//

/*
 This view controller is responsible for collecting and storing user information such as date of birth, gender, height, weight, and activity level. It includes various UIPickerViews for selecting options and a UIDatePicker for selecting the date of birth. The user inputs are saved to Firebase Realtime Database. The page is intended to be used when a user first sets up their profile in the FitCore app.
*/

import UIKit
import FirebaseFirestoreSwift
import Firebase
import FirebaseAuth
import FirebaseDatabase


// Data model to store user profile information
struct UserProfile {
    var dateOfBirth: String?
    var gender: String?
    var height: String?
    var weight: String?
    var activityLevel: String?
    
    // Initializer for the UserProfile struct
    init(dateOfBirth: String?, gender: String?, height: String?, weight: String?, activityLevel: String?) {
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.height = height
        self.weight = weight
        self.activityLevel = activityLevel
    }
}

class SettingsINTPageViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource ,UITextFieldDelegate{

    
    // Outlet for date of birth input field
    @IBOutlet weak var DateOfBirth: UITextField!
    
    // Outlet for gender input field
    @IBOutlet weak var Gender: UITextField!
    
    // Outlet for height input field
    @IBOutlet weak var Height: UITextField!
    
    // Outlet for weight input field
    @IBOutlet weak var Weight: UITextField!
    
    // Outlet for activity level input field
    @IBOutlet weak var Activitylevel: UITextField!
 
    
    // MARK: - Picker Setup
    
    // UIPickerView for Activity Level
    let activityLevelPicker = UIPickerView()
    let activityLevels = ["Extremely active", "Moderately active", "Not active"]
    
    // UIPickerView for Gender
    let genderPicker = UIPickerView()
    let genders = ["Male", "Female", "Other"]
    
    // UIDatePicker for Date of Birth
    let datePicker = UIDatePicker()
    
    // UIPickerView for Weight
    let weightPicker = UIPickerView()
    let weights: [String] = {
        var weights: [String] = []
        for kg in 30...200 {
            weights.append("\(kg) kg")
        }
        return weights
    }()
    
    // UIPickerView for Height
    let heightPicker = UIPickerView()
    let heights: [String] = {
        var heights: [String] = []
        for cm in 100...250 {
            heights.append("\(cm) cm")
        }
        return heights
    }()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if user is authenticated
        if Auth.auth().currentUser != nil {
            // Setup pickers
            setupPickers()
        } else {
            // Handle case where user is not authenticated
            // For example, show a login screen or redirect to a login page
        }
    }
    
    // MARK: - Picker Setup Functions
    
    // Setup pickers for input fields
    func setupPickers() {
        // Setup delegates
        DateOfBirth.delegate = self
        Gender.delegate = self
        Height.delegate = self
        Weight.delegate = self
        Activitylevel.delegate = self
        
        // Setup UIPickerView for Activity Level
        Activitylevel.inputView = activityLevelPicker
        activityLevelPicker.delegate = self
        
        // Setup UIPickerView for Gender
        Gender.inputView = genderPicker
        genderPicker.delegate = self
        
        // Setup UIPickerView for Weight
        Weight.inputView = weightPicker
        weightPicker.delegate = self
        
        // Setup UIPickerView for Height
        Height.inputView = heightPicker
        heightPicker.delegate = self
        
        // Setup UIDatePicker for Date of Birth
        setupDatePicker()
        
        // Setup done buttons for pickers
        setupDoneButtonForPicker(inputView: Activitylevel)
        setupDoneButtonForPicker(inputView: Gender)
        setupDoneButtonForPicker(inputView: Weight)
        setupDoneButtonForPicker(inputView: Height)
    }
    
    // Setup UIDatePicker for Date of Birth
    func setupDatePicker() {
        // Configure date picker mode
        datePicker.datePickerMode = .date
        
        // Create a toolbar with done button for date picker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(datePickerDoneButtonTapped))
        toolbar.setItems([doneButton], animated: true)
        
        // Assign toolbar to text field
        DateOfBirth.inputAccessoryView = toolbar
        
        // Assign date picker to text field
        DateOfBirth.inputView = datePicker
    }
    
    // Setup done button for pickers
    func setupDoneButtonForPicker(inputView: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(pickerDoneButtonTapped))
        toolbar.setItems([doneButton], animated: true)
        
        inputView.inputAccessoryView = toolbar
    }
    
    // MARK: - Picker Action Functions
    
    // Action when date picker's done button is tapped
    @objc func datePickerDoneButtonTapped() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        DateOfBirth.text = dateFormatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    // Action when picker's done button is tapped
    @objc func pickerDoneButtonTapped() {
        self.view.endEditing(true)
    }
    
    // MARK: - UIPickerView DataSource Methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == activityLevelPicker {
            return activityLevels.count
        } else if pickerView == genderPicker {
            return genders.count
        } else if pickerView == weightPicker {
            return weights.count
        } else {
            return heights.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == activityLevelPicker {
            return activityLevels[row]
        } else if pickerView == genderPicker {
            return genders[row]
        } else if pickerView == weightPicker {
            return weights[row]
        } else {
            return heights[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == activityLevelPicker {
            Activitylevel.text = activityLevels[row]
        } else if pickerView == genderPicker {
            Gender.text = genders[row]
        } else if pickerView == weightPicker {
            Weight.text = weights[row]
        } else {
            Height.text = heights[row]
        }
    }
    
    // MARK: - UITextFieldDelegate Methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == DateOfBirth {
            datePicker.datePickerMode = .date
        }
    }
    
    // MARK: - Storing User Information
    
    // Function to store user information in Firebase
    func storeUserInfo(userProfile: UserProfile) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        // Default values for user profile
        let defaultValues: [String: Any] = [
            "dateOfBirth": "08/08/2004",
            "gender": "Male",
            "height": "182",
            "weight": "78",
            "activityLevel": "Moderately active"
        ]
        
        // User information to be stored
        let userInfo: [String: Any] = [
            "dateOfBirth": userProfile.dateOfBirth ?? defaultValues["dateOfBirth"] as Any,
            "gender": userProfile.gender ?? defaultValues["gender"] as Any,
            "height": userProfile.height ?? defaultValues["height"] as Any,
            "weight": userProfile.weight ?? defaultValues["weight"] as Any,
            "activityLevel": userProfile.activityLevel ?? defaultValues["activityLevel"] as Any
        ]
        
        let databaseRef = Database.database().reference()
        
        // Save user information under the user's unique ID
        databaseRef.child("userProfiles").child(uid).setValue(userInfo) { (error, ref) in
            if let error = error {
                print("Error saving user information: \(error.localizedDescription)")
            } else {
                print("User information saved successfully")
                // Optionally, navigate to the next screen or perform other actions
            }
        }
    }
    // MARK: - User Interaction
       
    // Action for ConfirmDetails button tapped
    @IBAction func confirmDetailsButtonTapped(_ sender: Any) {
        guard let dateOfBirth = DateOfBirth.text,
              let gender = Gender.text,
              let height = Height.text,
              let weight = Weight.text,
              let activityLevel = Activitylevel.text else {
            //checking if all fields are completed
            showAlert(message: "Please fill in all fields.")
            return
            
            
    }
        
        // Check if any field is empty
        if dateOfBirth.isEmpty || gender.isEmpty || height.isEmpty || weight.isEmpty || activityLevel.isEmpty {
            // Show alert if any field is empty
            showAlert(message: "Please fill in all fields.")
            return
        }
        
        // Create a UserProfile object
        let userProfile = UserProfile(dateOfBirth: dateOfBirth, gender: gender, height: height, weight: weight, activityLevel: activityLevel)
        
        // Store user information in Firebase
        storeUserInfo(userProfile: userProfile)
        
        // Present the TabBarController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "HomePageViewController") as? UITabBarController {
            // Ensure the modal presentation style is set to full screen
            tabBarController.modalPresentationStyle = .fullScreen
            // Present the TabBarController
            self.present(tabBarController, animated: true, completion: nil)
        }
    }

    // Function to clear text fields
    func clearTextFields() {
        DateOfBirth.text = ""
        Gender.text = ""
        Height.text = ""
        Weight.text = ""
        Activitylevel.text = ""
    }
    
    // Function to show an alert
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}


/*
References:
- Apple Developer Documentation - [UIPickerView](https://developer.apple.com/documentation/uikit/uipickerview)
- Apple Developer Documentation - [UITextField](https://developer.apple.com/documentation/uikit/uitextfield)
- Apple Developer Documentation - [UIDatePicker](https://developer.apple.com/documentation/uikit/uidatepicker)
- Apple Developer Documentation - [UIToolbar](https://developer.apple.com/documentation/uikit/uitoolbar)
- Firebase Documentation - [Auth.auth](https://firebase.google.com/docs/reference/swift/firebaseauth/api/reference/auth)
- Firebase Documentation - [Database.database](https://firebase.google.com/docs/database/admin/start)
*/
