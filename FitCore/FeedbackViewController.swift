//
//  FeedbackViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 8/6/2024.
//
// ViewController for collecting user feedback and rating

import UIKit
import MessageUI

class FeedbackViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    
       // Label for prompting user to give feedback
       private let feedbackLabel: UILabel = {
           let label = UILabel()
           label.text = "Tell us your experience"
           label.font = UIFont(name: "Geeza Pro Bold", size: 24)
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       // Text view for entering feedback
       private let feedbackTextView: UITextView = {
           let textView = UITextView()
           textView.font = UIFont(name: "Geeza Pro", size: 16)
           textView.layer.borderColor = UIColor.systemGray4.cgColor
           textView.layer.borderWidth = 1.0
           textView.layer.cornerRadius = 8.0
           textView.translatesAutoresizingMaskIntoConstraints = false
           return textView
       }()
       
       // Label for prompting user to rate the app
       private let ratingLabel: UILabel = {
           let label = UILabel()
           label.text = "Rate us"
           label.font = UIFont(name: "Geeza Pro Bold", size: 24)
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       // Stack view for displaying star rating buttons
       private let starStackView: UIStackView = {
           let stackView = UIStackView()
           stackView.axis = .horizontal
           stackView.distribution = .fillEqually
           stackView.spacing = 8
           stackView.translatesAutoresizingMaskIntoConstraints = false
           return stackView
       }()
       
       // Button for submitting feedback
       private let submitButton: UIButton = {
           let button = UIButton(type: .system)
           button.setTitle("Submit", for: .normal)
           button.titleLabel?.font = UIFont(name: "Geeza Pro Bold", size: 18)
           button.addTarget(self, action: #selector(submitFeedback), for: .touchUpInside)
           button.translatesAutoresizingMaskIntoConstraints = false
           return button
       }()
       
       // Variable to store the selected rating
       private var selectedRating = 0
       
       // MARK: - View Lifecycle
       
       override func viewDidLoad() {
           super.viewDidLoad()
           
           // Set up the view controller
           self.view.backgroundColor = .systemBackground
           self.title = "Feedback"
           
           // Set up star rating system
           for i in 1...5 {
               let starButton = UIButton()
               starButton.tag = i
               starButton.setImage(UIImage(systemName: "star"), for: .normal)
               starButton.setImage(UIImage(systemName: "star.fill"), for: .selected)
               starButton.tintColor = .systemYellow // Gold color for the stars
               starButton.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
               starStackView.addArrangedSubview(starButton)
           }
           
           // Add subviews
           view.addSubview(feedbackLabel)
           view.addSubview(feedbackTextView)
           view.addSubview(ratingLabel)
           view.addSubview(starStackView)
           view.addSubview(submitButton)
           
           // Set up constraints
           NSLayoutConstraint.activate([
               feedbackLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32), // Lowered start position
               feedbackLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
               feedbackLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
               
               feedbackTextView.topAnchor.constraint(equalTo: feedbackLabel.bottomAnchor, constant: 16),
               feedbackTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
               feedbackTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
               feedbackTextView.heightAnchor.constraint(equalToConstant: 150),
               
               ratingLabel.topAnchor.constraint(equalTo: feedbackTextView.bottomAnchor, constant: 16),
               ratingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
               ratingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
               
               starStackView.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 8),
               starStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
               starStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
               starStackView.heightAnchor.constraint(equalToConstant: 44),
               
               submitButton.topAnchor.constraint(equalTo: starStackView.bottomAnchor, constant: 24),
               submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
           ])
       }
       
       // MARK: - Action Handlers
       
       // Handles tap on star buttons for rating
       @objc private func starTapped(_ sender: UIButton) {
           selectedRating = sender.tag
           for case let button as UIButton in starStackView.arrangedSubviews {
               button.isSelected = button.tag <= selectedRating
           }
       }
       
       // Handles submission of feedback
       @objc private func submitFeedback() {
           guard MFMailComposeViewController.canSendMail() else {
               // Show alert if mail services are not available
               let alert = UIAlertController(title: "Error", message: "Mail services are not available", preferredStyle: .alert)
               alert.addAction(UIAlertAction(title: "OK", style: .default))
               self.present(alert, animated: true)
               return
           }
           
           let mailComposeVC = MFMailComposeViewController()
           mailComposeVC.mailComposeDelegate = self
           mailComposeVC.setToRecipients(["deveshgurusinghe@gmail.com"])
           mailComposeVC.setSubject("App Feedback")
           
           let feedback = feedbackTextView.text ?? "No feedback provided"
           let rating = String(repeating: "⭐️", count: selectedRating)
           let messageBody = """
           Feedback:
           \(feedback)
           
           Rating:
           \(rating)
           """
           
           mailComposeVC.setMessageBody(messageBody, isHTML: false)
           
           self.present(mailComposeVC, animated: true)
       }
       
       // MARK: - MFMailComposeViewControllerDelegate
       
       // Handles the result of mail composition
       func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
           controller.dismiss(animated: true)
           
           if result == .sent {
               let alert = UIAlertController(title: "Thank you!", message: "Your feedback has been sent.", preferredStyle: .alert)
               alert.addAction(UIAlertAction(title: "OK", style: .default))
               self.present(alert, animated: true)
           }
       }
   }



/*
References:
- Apple Developer Documentation - [UILabel](https://developer.apple.com/documentation/uikit/uilabel) for creating and styling the feedbackLabel.
- Apple Developer Documentation - [UITextView](https://developer.apple.com/documentation/uikit/uitextview) for creating and styling the feedbackTextView.
- Apple Developer Documentation - [UIButton](https://developer.apple.com/documentation/uikit/uibutton) for creating and styling the submitButton and handling button actions.
- Apple Developer Documentation - [UIStackView](https://developer.apple.com/documentation/uikit/uistackview) for arranging the star rating buttons in a horizontal stack.
- Apple Developer Documentation - [UIImage](https://developer.apple.com/documentation/uikit/uiimage) for setting star images in star buttons.
- Apple Developer Documentation - [MFMailComposeViewController](https://developer.apple.com/documentation/messageui/mfmailcomposeviewcontroller) for composing and sending email feedback.
- Stack Overflow - [iOS Development](https://stackoverflow.com/questions/tagged/ios) for general iOS development queries and solutions.
- YouTube - [How to Add Feedback Feature in iOS App](https://www.youtube.com/watch?v=xxxxxx) for a tutorial on implementing feedback functionality in iOS apps.
*/
