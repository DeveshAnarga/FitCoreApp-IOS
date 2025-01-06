//
//  SettingsPageViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 8/5/2024.
//

/*
 This view controller handles the settings page where users can update their personal information such as date of birth, gender, height, weight, and activity level.
 The data is stored in Firebase Realtime Database and Core Data for persistence. The user can also delete their account, which will remove all their data from the database.
 */



import UIKit
import FirebaseDatabase
import FirebaseAuth
import CoreData


class SettingsPageViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var failedReauthAttempts = 0
    
    // Variable to keep track of failed re-authentication attempts
    @IBOutlet weak var DateOfBirth: UITextField!
    
    // Outlet for gender input field
    @IBOutlet weak var Gender: UITextField!
    
    // Outlet for height input field
    @IBOutlet weak var Height: UITextField!
    
    // Outlet for weight input field
    @IBOutlet weak var Weight: UITextField!
    
    // Outlet for activity level input field
    @IBOutlet weak var Activitylevel: UITextField!
    
    
    
    // UIPickerView for Activity Level selection
    let activityLevelPicker = UIPickerView()
    // Array of activity level options
    let activityLevels = ["Extremely active", "Moderately active", "Not active"]
    
    // UIPickerView for Gender selection
    let genderPicker = UIPickerView()
    // Array of gender options
    let genders = ["Male", "Female", "Other"]
    
    // UIDatePicker for Date of Birth selection
    let datePicker = UIDatePicker()
    
    // UIPickerView for Weight selection
    let weightPicker = UIPickerView()
    // Array of weight options, generated dynamically
    let weights: [String] = {
        var weights: [String] = []
        for kg in 30...200 {
            weights.append("\(kg) kg")
        }
        return weights
    }()
    
    // UIPickerView for Height selection
    let heightPicker = UIPickerView()
    // Array of height options, generated dynamically
    let heights: [String] = {
        var heights: [String] = []
        for cm in 100...250 {
            heights.append("\(cm) cm")
        }
        return heights
    }()
    
    // User profile variable to store retrieved user information
    var userProfile: UserProfile?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveUserProfile()
        if Auth.auth().currentUser != nil {
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
            setupDoneButtonForPicker(inputView: Activitylevel)
            setupDoneButtonForPicker(inputView: Gender)
            setupDoneButtonForPicker(inputView: Weight)
            setupDoneButtonForPicker(inputView: Height)
        } else {
            // Handle case where user is not authenticated
            // For example, show a login screen or redirect to a login page
        }
        
        // Always make the pickers appear when text fields are pressed
        DateOfBirth.becomeFirstResponder()
        Gender.becomeFirstResponder()
        Height.becomeFirstResponder()
        Weight.becomeFirstResponder()
        Activitylevel.becomeFirstResponder()
    }
    
    // MARK: - Retrieve User Profile
    func retrieveUserProfile() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        let ref = Database.database().reference().child("userProfiles").child(userID)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any] else { return }
            self.userProfile = UserProfile(dateOfBirth: userData["dateOfBirth"] as? String ?? "",
                                           gender: userData["gender"] as? String ?? "",
                                           height: userData["height"] as? String ?? "",
                                           weight: userData["weight"] as? String ?? "",
                                           activityLevel: userData["activityLevel"] as? String ?? "")
            self.populateFields()
        }
    }
    
    // MARK: - Populate Fields
    func populateFields() {
        guard let userProfile = userProfile else { return }
        DateOfBirth.text = userProfile.dateOfBirth
        Gender.text = userProfile.gender
        Height.text = userProfile.height
        Weight.text = userProfile.weight
        Activitylevel.text = userProfile.activityLevel
    }
    
    
    // This function sets up the UIDatePicker for the DateOfBirth UITextField
    func setupDatePicker() {
        // Configure the date picker mode to display dates
        datePicker.datePickerMode = .date
        
        // Create a toolbar with a 'Done' button for the date picker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(datePickerDoneButtonTapped))
        toolbar.setItems([doneButton], animated: true)
        
        // Assign the toolbar as an accessory view to the DateOfBirth text field
        DateOfBirth.inputAccessoryView = toolbar
        
        // Assign the date picker as the input view for the DateOfBirth text field
        DateOfBirth.inputView = datePicker
    }
    
    // This function sets up a toolbar with a 'Done' button for the given input view (UITextField)
    func setupDoneButtonForPicker(inputView: UITextField) {
        // Create a toolbar with a 'Done' button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(pickerDoneButtonTapped))
        toolbar.setItems([doneButton], animated: true)
        
        // Assign the toolbar as an accessory view to the specified input view (text field)
        inputView.inputAccessoryView = toolbar
    }
    
    // Action method called when the 'Done' button on the date picker toolbar is tapped
    @objc func datePickerDoneButtonTapped() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        DateOfBirth.text = dateFormatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    // Action method called when the 'Done' button on the picker view toolbar is tapped
    @objc func pickerDoneButtonTapped() {
        self.view.endEditing(true)
    }
    
    // Returns the number of components (columns) in the picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Returns the number of rows in each component of the picker view
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
    
    // Returns the title for each row in the picker view
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
    
    // Handles the selection of a row in the picker view
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
    
    
    // Function to store user information in Firebase
    func storeUserInfo(userProfile: UserProfile) {
        // Check if the user is authenticated and get the user's unique ID
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        // Create a dictionary to store user information
        let userInfo: [String: Any] = [
            "dateOfBirth": userProfile.dateOfBirth,
            "gender": userProfile.gender,
            "height": userProfile.height,
            "weight": userProfile.weight,
            "activityLevel": userProfile.activityLevel
        ]
        
        // Get a reference to the Firebase Realtime Database
        let databaseRef = Database.database().reference()
        
        // Save the user information under the user's unique ID in the "userProfiles" node
        databaseRef.child("userProfiles").child(uid).setValue(userInfo) { (error, ref) in
            if let error = error {
                // Print an error message if there is an issue saving the user information
                print("Error saving user information: \(error.localizedDescription)")
            } else {
                // Print a success message if the user information is saved successfully
                print("User information saved successfully")
                // Optionally, navigate to the next screen or perform other actions
            }
        }
    }
    
    
    // Action method for confirming and saving user details
    @IBAction func confirmDetailsButtonTapped(_ sender: Any) {
        // Ensure all text fields are filled
        guard let dateOfBirth = DateOfBirth.text,
              let gender = Gender.text,
              let height = Height.text,
              let weight = Weight.text,
              let activityLevel = Activitylevel.text else {
            print("Please fill in all fields.")
            return
        }
        
        // Check if the user is authenticated
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        // Create a dictionary to store user information
        let userInfo: [String: Any] = [
            "dateOfBirth": dateOfBirth,
            "gender": gender,
            "height": height,
            "weight": weight,
            "activityLevel": activityLevel
        ]
        
        // Get a reference to the Firebase Realtime Database
        let databaseRef = Database.database().reference()
        
        // Show an alert indicating that the changes are being saved
        let savingAlert = UIAlertController(title: nil, message: "Saving changes...", preferredStyle: .alert)
        present(savingAlert, animated: true, completion: nil)
        
        // Save the user information under the user's unique ID in the "userProfiles" node
        databaseRef.child("userProfiles").child(userID).setValue(userInfo) { (error, ref) in
            // Dismiss the saving alert after attempting to save the data
            savingAlert.dismiss(animated: true) {
                if let error = error {
                    // Print an error message if there is an issue saving the user information
                    print("Error saving user information: \(error.localizedDescription)")
                    
                    // Show an alert for error
                    let errorAlert = UIAlertController(title: "Error", message: "Failed to save changes: \(error.localizedDescription)", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                } else {
                    // Print a success message if the user information is saved successfully
                    print("User information saved successfully")
                    
                    // Show a success alert
                    let successAlert = UIAlertController(title: "Success", message: "Changes have been saved successfully.", preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(successAlert, animated: true, completion: nil)
                    
                    // Send a notification to update the HomePageViewController
                    NotificationCenter.default.post(name: Notification.Name("UserProfileUpdated"), object: nil)
                }
            }
        }
    }
    
    
    
    // Action for DeleteAccount button tapped
    // Function to handle the deletion of the user's account from the database and authentication
    @IBAction func deleteAccountButtonTapped(_ sender: Any) {
        // Create an alert to confirm account deletion
        let alert = UIAlertController(title: "Confirm Deletion", message: "Are you sure you want to delete your account? All images and information will be permanently deleted.", preferredStyle: .alert)
        
        // Add the "Delete" action to the alert
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.promptForReauthentication()
        }
        alert.addAction(deleteAction)
        
        // Add the "Cancel" action to the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        // Present the alert to the user
        present(alert, animated: true, completion: nil)
    }
    
    // Function to prompt the user for reauthentication
    func promptForReauthentication() {
        // Ensure the user is authenticated and retrieve their email
        guard let user = Auth.auth().currentUser, let email = user.email else {
            print("User not authenticated")
            return
        }
        
        // Create an alert for reauthentication
        let alert = UIAlertController(title: "Reauthenticate", message: "Please enter your password to delete your account.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        // Add the "Confirm" action to the alert
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
            let password = alert.textFields?.first?.text ?? ""
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.reauthenticate(with: credential) { _, error in
                if let error = error {
                    print("Reauthentication error: \(error.localizedDescription)")
                    self.failedReauthAttempts += 1
                    if self.failedReauthAttempts >= 2 {
                        self.presentForgotPasswordOption(email: email)
                    } else {
                        self.showAlert(message: "Reauthentication failed. Please try again.")
                    }
                } else {
                    self.failedReauthAttempts = 0
                    self.deleteAccount()
                }
            }
        }
        alert.addAction(confirmAction)
        
        // Add the "Cancel" action to the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        // Present the reauthentication alert to the user
        present(alert, animated: true, completion: nil)
    }
    
    // Function to present an option for password reset if reauthentication fails
    func presentForgotPasswordOption(email: String) {
        let alert = UIAlertController(title: "Forgot Password?", message: "Would you like to reset your password?", preferredStyle: .alert)
        
        // Add the "Reset Password" action to the alert
        let resetAction = UIAlertAction(title: "Reset Password", style: .default) { _ in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    self.showAlert(message: "Error: \(error.localizedDescription)")
                } else {
                    self.showAlert(message: "A password reset email has been sent to \(email).")
                }
            }
        }
        alert.addAction(resetAction)
        
        // Add the "Cancel" action to the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        // Present the password reset alert to the user
        present(alert, animated: true, completion: nil)
    }
    
    // Function to delete the user's account
    func deleteAccount() {
        // Ensure the user is authenticated
        guard let user = Auth.auth().currentUser else {
            print("User not authenticated")
            return
        }
        
        let uid = user.uid
        
        // Delete user data from the Realtime Database
        let databaseRef = Database.database().reference()
        databaseRef.child("userProfiles").child(uid).removeValue { error, _ in
            if let error = error {
                print("Error deleting user profile from Realtime Database: \(error.localizedDescription)")
            } else {
                print("User profile deleted from Realtime Database successfully")
                
                // Delete user data from Core Data
                self.deleteAllNotesFromCoreData()
                
                // Delete the user account from Firebase Authentication
                user.delete { error in
                    if let error = error {
                        print("Error deleting account: \(error.localizedDescription)")
                    } else {
                        print("Account deleted successfully")
                        // Clear text fields and reset the root view controller
                        self.clearTextFields()
                        self.resetRootViewController()
                    }
                }
            }
        }
    }
    
    // Function to delete all notes from Core Data
    func deleteAllNotesFromCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Note")
        
        do {
            // Fetch all notes from Core Data
            let fetchResults = try context.fetch(fetchRequest) as? [NSManagedObject]
            if let results = fetchResults {
                // Delete each fetched note from the context
                for result in results {
                    context.delete(result)
                }
                // Save the context to persist the deletions
                try context.save()
                print("All notes deleted from Core Data successfully")
            } else {
                print("No notes found in Core Data")
            }
        } catch let error {
            // Handle any errors during the fetch or delete operations
            print("Failed to delete notes from Core Data: \(error.localizedDescription)")
        }
    }
    
    // Function to reset the root view controller to the initial view controller
    func resetRootViewController() {
        guard let window = UIApplication.shared.windows.first else {
            return
        }
        
        // Load the initial view controller from the Main storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateInitialViewController()
        
        // Set the initial view controller as the root view controller
        window.rootViewController = initialViewController
        window.makeKeyAndVisible()
    }
    
    // Function to clear all user input text fields
    func clearTextFields() {
        DateOfBirth.text = ""
        Gender.text = ""
        Height.text = ""
        Weight.text = ""
        Activitylevel.text = ""
    }
    
    // Function to show an alert with a given message
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
- Apple Developer Documentation - [DateFormatter](https://developer.apple.com/documentation/foundation/dateformatter)
- Apple Developer Documentation - [UIBarButtonItem](https://developer.apple.com/documentation/uikit/uibarbuttonitem)
- Apple Developer Documentation - [UIDatePicker](https://developer.apple.com/documentation/uikit/uidatepicker)
- Apple Developer Documentation - [UIToolbar](https://developer.apple.com/documentation/uikit/uitoolbar)
- Apple Developer Documentation - [UIAlertController](https://developer.apple.com/documentation/uikit/uialertcontroller)
- Firebase Documentation - [Auth.auth](https://firebase.google.com/docs/reference/swift/firebaseauth/api/reference/auth)
- Firebase Documentation - [Database.database](https://firebase.google.com/docs/database/admin/start)
- Apple Developer Documentation - [NSFetchRequest](https://developer.apple.com/documentation/coredata/nsfetchrequest)
- Apple Developer Documentation - [UIApplication](https://developer.apple.com/documentation/uikit/uiapplication)
- Stack Overflow - [How to use UIPickerView](https://stackoverflow.com/questions/11620510/how-to-use-uipickerview)
- Ray Wenderlich - [Core Data Tutorial](https://www.raywenderlich.com/173972/getting-started-with-core-data-tutorial)
- Stack Overflow - [How to Delete Data from Core Data](https://stackoverflow.com/questions/37931214/delete-all-entities-in-core-data-swift)
- YouTube - [Firebase Authentication in iOS](https://www.youtube.com/watch?v=pEhZwHGOH_Y)
- YouTube - [Core Data Tutorial](https://www.youtube.com/watch?v=-aTCmz9PTOQ)
*/

