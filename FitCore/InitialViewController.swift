//
//  InitialViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 26/5/2024.
//
/*
 This view controller is the initial screen for the FitCore app. It serves as the entry point where animations and checks for user authentication status are performed.
 If an authenticated user is detected, the app navigates them to the appropriate page based on their profile status.
 If no authenticated user is found, it navigates to the signup page. It includes visual elements like animations for lightning and logo, and handles user profile status verification through Firebase.
*/

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestoreSwift
import FirebaseDatabaseInternal

class InitialViewController: UIViewController {
    
    // MARK: - UI Elements
    // Left image view for the bull face
    let leftImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "bull_face_left")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Right image view for the bull face
    let rightImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "bull_face_right")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Label for the app name "Fitcore"
    let fitcoreLabel: UILabel = {
        let label = UILabel()
        label.text = "Fitcore"
        label.font = UIFont(name: "Impact", size: 48) // Using Impact font for a more striking appearance
        label.textColor = .white
        label.alpha = 0.0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Layer for lightning animation
    let lightningLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 3.0
        layer.lineCap = .round
        layer.lineJoin = .round
        return layer
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        animateLightning()
        
        // Check if there is an authenticated user
        if let user = Auth.auth().currentUser {
            user.reload { (error) in
                if let error = error {
                    print("Error reloading user: \(error.localizedDescription)")
                    self.navigateToSignupPage()
                } else if Auth.auth().currentUser == nil {
                    print("No authenticated user after reload.")
                    self.navigateToSignupPage()
                } else {
                    print("User is signed in: \(user.uid)")
                    self.checkUserExistenceInAuthDatabase(for: user)
                }
            }
        } else {
            // No authenticated user, navigate to signup page
            print("No authenticated user.")
            navigateToSignupPage()
        }
    }
    
    // MARK: - Setup UI
    // This function sets up the user interface elements.
    func setupUI() {
        view.backgroundColor = .black
        
        // Add the lightning layer and image views to the view hierarchy.
        view.layer.addSublayer(lightningLayer)
        view.addSubview(leftImageView)
        view.addSubview(rightImageView)
        view.addSubview(fitcoreLabel)
        
        // Set up constraints for positioning the UI elements.
        NSLayoutConstraint.activate([
            leftImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            leftImageView.trailingAnchor.constraint(equalTo: view.centerXAnchor),
            leftImageView.widthAnchor.constraint(equalToConstant: 150),
            leftImageView.heightAnchor.constraint(equalToConstant: 300),
            
            rightImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            rightImageView.leadingAnchor.constraint(equalTo: view.centerXAnchor),
            rightImageView.widthAnchor.constraint(equalToConstant: 150),
            rightImageView.heightAnchor.constraint(equalToConstant: 300),
            
            fitcoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fitcoreLabel.topAnchor.constraint(equalTo: rightImageView.bottomAnchor, constant: 20)
        ])
    }
    
    // MARK: - Lightning Animation
    // This function creates and animates the lightning effect.
    func animateLightning() {
        let lightningPath = UIBezierPath()
        lightningPath.move(to: CGPoint(x: view.bounds.midX, y: 0))
        lightningPath.addLine(to: CGPoint(x: view.bounds.midX + 20, y: 100))
        lightningPath.addLine(to: CGPoint(x: view.bounds.midX - 20, y: 200))
        lightningPath.addLine(to: CGPoint(x: view.bounds.midX + 30, y: 300))
        lightningPath.addLine(to: CGPoint(x: view.bounds.midX - 30, y: 400))
        lightningPath.addLine(to: CGPoint(x: view.bounds.midX + 40, y: 500))
        lightningPath.addLine(to: CGPoint(x: view.bounds.midX, y: view.bounds.height))
        
        lightningLayer.path = lightningPath.cgPath
        
        let lightningAnimation = CABasicAnimation(keyPath: "strokeEnd")
        lightningAnimation.duration = 0.2 // Faster lightning
        lightningAnimation.fromValue = 0
        lightningAnimation.toValue = 1
        lightningAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        lightningAnimation.fillMode = .forwards
        lightningAnimation.isRemovedOnCompletion = false
        
        lightningLayer.add(lightningAnimation, forKey: "lightningAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.flickerLightning()
        }
    }
    
    // MARK: - Flicker Effect
    // This function creates a flicker effect for the lightning animation.
    func flickerLightning() {
        UIView.animate(withDuration: 0.1, animations: {
            self.view.backgroundColor = .white
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.view.backgroundColor = .black
            }) { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.view.backgroundColor = .white
                }) { _ in
                    UIView.animate(withDuration: 0.1, animations: {
                        self.view.backgroundColor = .black
                    }) { _ in
                        self.animateLogo()
                    }
                }
            }
        }
    }
    
    // MARK: - Logo Animation
    // This function animates the logo elements into view.
    func animateLogo() {
        leftImageView.transform = CGAffineTransform(translationX: -view.frame.width / 2 - leftImageView.frame.width / 2, y: 0)
        rightImageView.transform = CGAffineTransform(translationX: view.frame.width / 2 + rightImageView.frame.width / 2, y: 0)
        
        UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.leftImageView.transform = CGAffineTransform.identity
            self.rightImageView.transform = CGAffineTransform.identity
        }, completion: { _ in
            self.animateLabel()
        })
    }
    
    // MARK: - Label Animation
    // This function animates the Fitcore label into view.
    func animateLabel() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.0
        scaleAnimation.toValue = 1.0
        scaleAnimation.duration = 0.5
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        self.fitcoreLabel.layer.add(scaleAnimation, forKey: "scale")
        self.fitcoreLabel.alpha = 1.0
    }
    
    // MARK: - Account Verification
    // This function checks if the user exists in the authentication database.
    func checkUserExistenceInAuthDatabase(for user: User) {
        Auth.auth().fetchSignInMethods(forEmail: user.email ?? "") { signInMethods, error in
            if let error = error {
                print("Error fetching sign-in methods: \(error.localizedDescription)")
                return
            }
            
            if let signInMethods = signInMethods, signInMethods.isEmpty {
                print("No sign-in methods found, navigating to signup page.")
                self.navigateToSignupPage()
            } else {
                print("User exists, checking user profile status.")
                self.checkUserProfileStatus(for: user)
            }
        }
    }

    // This function checks if the user has a profile in the database.
    func checkUserProfileStatus(for user: User) {
        let ref = Database.database().reference().child("userProfiles").child(user.uid)
        ref.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                // User has a profile, navigate to home page
                print("User has a profile, navigating to home page.")
                self.navigateToHome()
            } else {
                // User does not have a profile, navigate to Settings page
                print("User does not have a profile, navigating to settings page.")
                self.navigateToSettingsPage()
            }
        }
    }
    
    
    // MARK: - Navigation

    // This function navigates to the signup page.
    // It uses UIStoryboard to instantiate the SignupPage_FitCore view controller and presents it modally in full-screen mode.
    func navigateToSignupPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let signupVC = storyboard.instantiateViewController(withIdentifier: "SignupPage_FitCore") as? UIViewController {
            signupVC.modalPresentationStyle = .fullScreen
            self.present(signupVC, animated: true, completion: nil)
        }
    }

    // This function navigates to the home page.
    // It uses UIStoryboard to instantiate the HomePageViewController and presents it modally in full-screen mode.
    func navigateToHome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let homeVC = storyboard.instantiateViewController(withIdentifier: "HomePageViewController") as? UIViewController {
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: true, completion: nil)
        }
    }

    // This function navigates to the settings page.
    // It uses UIStoryboard to instantiate the SettingsPageViewController and presents it modally in full-screen mode.
    func navigateToSettingsPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let settingsVC = storyboard.instantiateViewController(withIdentifier: "SettingsPageViewController") as? UIViewController {
            settingsVC.modalPresentationStyle = .fullScreen
            self.present(settingsVC, animated: true, completion: nil)
        }
    }
}


/*
 References for Animations and UI Elements:

 Apple Developer Documentation - CABasicAnimation**: [CABasicAnimation](https://developer.apple.com/documentation/quartzcore/cabasicanimation)
    - This documentation explains how to use CABasicAnimation for creating basic animations in iOS, such as animating the properties of CALayer objects.

Apple Developer Documentation - UIBezierPath**: [UIBezierPath](https://developer.apple.com/documentation/uikit/uibezierpath)
    - This guide provides details on how to use UIBezierPath to define vector-based paths for shapes, such as the lightning effect in your animation.

 Stack Overflow - How to create lightning animation in iOS**: [Stack Overflow](https://stackoverflow.com/questions/17616221/how-to-create-lightning-animation-in-ios)
    - This discussion includes various approaches and code snippets for creating a lightning animation effect in iOS applications.

  YouTube - iOS Animation Tutorial: Custom UIView animations**: [YouTube](https://www.youtube.com/watch?v=bXMQypB3axs)
    - This tutorial video demonstrates how to create custom UIView animations, including moving and transforming UI elements like images.

  Ray Wenderlich - UIView Animations Tutorial: Getting Started**: [Ray Wenderlich](https://www.raywenderlich.com/905-uiview-animations-tutorial-getting-started)
    - This tutorial provides an in-depth guide on UIView animations, covering various techniques to animate UI elements.

Medium - Creating Cool Animations in Swift**: [Medium](https://medium.com/ios-os-x-development/creating-cool-animations-in-swift-16c2c1c1e8da)
    - An article that explores different types of animations that can be created in Swift, including transforming and animating UI elements.

 Apple Developer Documentation - UIView**: [UIView](https://developer.apple.com/documentation/uikit/uiview)
    - This documentation covers the basics of UIView, including how to manipulate its properties for animations.

 Apple Developer Documentation - UIImageView**: [UIImageView](https://developer.apple.com/documentation/uikit/uiimageview)
    - Provides details on using UIImageView, which is useful for handling and displaying images in iOS applications.

  Hacking with Swift - Animations with Swift**: [Hacking with Swift](https://www.hackingwithswift.com/read/32/overview)
    - A practical guide on creating animations in Swift, with examples and explanations of different animation techniques.
 */
