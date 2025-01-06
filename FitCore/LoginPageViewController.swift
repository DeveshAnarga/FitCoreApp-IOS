//
//  LoginPageViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 24/4/2024.
//

/*
 This view controller manages the login page of the FitCore app. It allows users to enter their email and password to log in or create a new account.
 It checks for network connectivity before attempting any login or account creation operations. The page also handles validation for email format and password length.
 Additionally, it provides feedback to the user through alerts and uses Firebase for authentication and user management.
*/


import UIKit
import FirebaseFirestoreSwift
import Firebase
import FirebaseAuth
import SystemConfiguration

class LoginPageViewController: UIViewController,UITextFieldDelegate {
    
    // MARK: - Getting User Information

    @IBOutlet weak var UserEmail: UITextField!
    @IBOutlet weak var UserPassword: UITextField!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set secure text entry for password field to hide the password as the user types.
        UserPassword.isSecureTextEntry = true
        
        // Set delegates for text fields to handle return key events.
        UserEmail.delegate = self
        UserPassword.delegate = self
        
        // Add toolbar with done button to email and password text fields to dismiss the keyboard.
        addDoneButtonToKeyboard(for: UserEmail)
        addDoneButtonToKeyboard(for: UserPassword)
        
        // Check network connectivity and show alert if not connected.
        checkNetworkConnectivity()
    }
    
    
    // MARK: - Network Connectivity
    // This function checks if the device is connected to the internet.
    func checkNetworkConnectivity() {
        if !isConnectedToNetwork() {
            // Create and show an alert if there is no internet connection.
            let alert = UIAlertController(title: "No Internet Connection",
                                          message: "Please check your internet connection and try again.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // This function checks the network reachability status.
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    // MARK: - Add Done Button to Keyboard
    // This function adds a done button to the keyboard for a given text field.
    func addDoneButtonToKeyboard(for textField: UITextField) {
        // Create a toolbar.
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        // Create a flexible space bar button item.
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Create a done button item.
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        
        // Add the button to the toolbar.
        toolbar.items = [flexibleSpace, doneButton]
        
        // Assign the toolbar to the text field's input accessory view.
        textField.inputAccessoryView = toolbar
    }
    
    // This function is called when the done button on the keyboard toolbar is tapped.
    @objc func doneButtonTapped() {
        // Dismiss the keyboard.
        view.endEditing(true)
    }
    
    // MARK: - UITextFieldDelegate Methods (if needed)
    // This function is called when the return key is tapped on the keyboard.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Dismiss the keyboard when return key is tapped.
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Create Account
    // This function is called when the Create Account button is tapped.
    @IBAction func CreateAccountButtonTapped(_ sender: UIButton) {
        guard let email = UserEmail.text,
              let password = UserPassword.text else {
            return
        }
        
        // Validate email format
        if !isValidEmail(email) {
            showAlert(message: "Please enter a valid email address.")
            return
        }
        
        // Check if password length is less than 6 characters
        if password.count < 6 {
            showAlert(message: "Password must be at least 6 characters long.")
            return
        }
        
        // Create user account with provided email and password.
        createUser(email: email, password: password)
        
    }
    
    // This function validates the format of the email.
       func isValidEmail(_ email: String) -> Bool {
           // Regular expression pattern for validating email format.
           let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
           let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
           return emailPredicate.evaluate(with: email)
       }
       
       // This function creates a new user account using Firebase Authentication.
       func createUser(email: String, password: String) {
           Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
               if let error = error as NSError? {
                   // Handle error
                   if let errorCode = AuthErrorCode.Code(rawValue: error.code) {
                       switch errorCode {
                       case .emailAlreadyInUse:
                           self.showAlert(message: "The email address is already in use by another account.")
                       default:
                           self.showAlert(message: "Error creating user: \(error.localizedDescription)")
                       }
                   }
               } else {
                   // User created successfully
                   print("User created successfully")
                   
                   // Sign in the user after account creation
                   Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
                       if let error = error {
                           // Handle sign-in error
                           print("Error signing in: \(error.localizedDescription)")
                       } else {
                           // User signed in successfully
                           print("User signed in successfully")
                           // Navigate to the settings page
                           self.navigateToSettingsPage()
                       }
                   }
               }
           }
       }
       
       // This function shows an alert with a given message.
       func showAlert(message: String) {
           let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           self.present(alert, animated: true, completion: nil)
       }
       
       // This function navigates to the settings page after successful sign-in.
       func navigateToSettingsPage() {
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           if let settingsVC = storyboard.instantiateViewController(withIdentifier: "SettingsPageViewController") as? UIViewController {
               settingsVC.modalPresentationStyle = .fullScreen
               self.present(settingsVC, animated: true, completion: nil)
           }
       }
   }


/*
   References:
   - Apple Developer Documentation - UITextFieldDelegate: [UITextFieldDelegate](https://developer.apple.com/documentation/uikit/uitextfielddelegate)
   - Apple Developer Documentation - UIAlertController: [UIAlertController](https://developer.apple.com/documentation/uikit/uialertcontroller)
   - Apple Developer Documentation - UIBarButtonItem: [UIBarButtonItem](https://developer.apple.com/documentation/uikit/uibarbuttonitem)
   - Apple Developer Documentation - UIToolbar: [UIToolbar](https://developer.apple.com/documentation/uikit/uitoolbar)
   - Apple Developer Documentation - Firebase Authentication: [FirebaseAuth](https://firebase.google.com/docs/auth)
   - Apple Developer Documentation - SCNetworkReachability: [SCNetworkReachability](https://developer.apple.com/documentation/systemconfiguration/scnetworkreachability)
   - Apple Developer Documentation - UIStoryboard: [UIStoryboard](https://developer.apple.com/documentation/uikit/uistoryboard)
   - Stack Overflow - Adding a Done Button to Keyboard: [Stack Overflow](https://stackoverflow.com/questions/24126678/adding-a-done-button-to-numberpad-in-ios)
   - YouTube - How to Check Network Connectivity in Swift: [YouTube](https://www.youtube.com/watch?v=Kl56sHf8HSg)
   - Medium - Firebase Authentication in iOS: [Medium](https://medium.com/firebase-developers/firebase-authentication-in-swift-52d5a5c7047d)
   - Ray Wenderlich - Handling Alerts in iOS: [Ray Wenderlich](https://www.raywenderlich.com/450-ios-alerts-and-action-sheets-getting-started)
*/

