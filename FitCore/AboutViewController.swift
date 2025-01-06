//
//  AboutViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 8/6/2024.
//This view controller displays information about the application and the third-party libraries used in its development. It provides details about Firebase, Edamam API, and DGCharts, along with links to their respective websites for further reference.


import UIKit

class AboutViewController: UIViewController {
    
    // MARK: - Properties
       
       // ScrollView to allow scrolling when content exceeds the screen size
       private let scrollView = UIScrollView()
       private let contentView = UIView()
       
       // Labels for displaying information about the app and third-party libraries
       private let headingLabel: UILabel = {
           let label = UILabel()
           label.text = "About"
           label.font = UIFont(name: "Geeza Pro Bold", size: 24)
           label.textAlignment = .center
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       private let descriptionLabel: UILabel = {
           let label = UILabel()
           label.text = "This app uses the following third-party libraries:"
           label.font = UIFont(name: "Geeza Pro Bold", size: 18)
           label.numberOfLines = 0
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       // Firebase information labels
       private let firebaseLabel: UILabel = {
           let label = UILabel()
           label.text = "Firebase"
           label.font = UIFont(name: "Geeza Pro Bold", size: 18)
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       private let firebaseDescriptionLabel: UILabel = {
           let label = UILabel()
           label.text = "Firebase is used for backend services such as authentication, database, and analytics. Developed by Google. [Firebase website](https://firebase.google.com)"
           label.font = UIFont(name: "Geeza Pro", size: 16)
           label.numberOfLines = 0
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       // Edamam API information labels
       private let edamamLabel: UILabel = {
           let label = UILabel()
           label.text = "Edamam API"
           label.font = UIFont(name: "Geeza Pro Bold", size: 18)
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       private let edamamDescriptionLabel: UILabel = {
           let label = UILabel()
           label.text = "Edamam API is used for retrieving nutritional information and recipe data. Developed by Edamam. [Edamam website](https://developer.edamam.com)"
           label.font = UIFont(name: "Geeza Pro", size: 16)
           label.numberOfLines = 0
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       // DGCharts information labels
       private let dgChartsLabel: UILabel = {
           let label = UILabel()
           label.text = "DGCharts"
           label.font = UIFont(name: "Geeza Pro Bold", size: 18)
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       private let dgChartsDescriptionLabel: UILabel = {
           let label = UILabel()
           label.text = "DGCharts is used for creating charts and data visualizations. Developed by DGCharts. [DGCharts website](https://github.com/DGChart)"
           label.font = UIFont(name: "Geeza Pro", size: 16)
           label.numberOfLines = 0
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       // MARK: - View Lifecycle
       
       override func viewDidLoad() {
           super.viewDidLoad()
           
           // Set up the view controller
           self.view.backgroundColor = .systemBackground
           self.title = "About"
           
           // Set up the scroll view and content view
           scrollView.translatesAutoresizingMaskIntoConstraints = false
           contentView.translatesAutoresizingMaskIntoConstraints = false
           
           view.addSubview(scrollView)
           scrollView.addSubview(contentView)
           
           // Add labels to the content view
           contentView.addSubview(headingLabel)
           contentView.addSubview(descriptionLabel)
           contentView.addSubview(firebaseLabel)
           contentView.addSubview(firebaseDescriptionLabel)
           contentView.addSubview(edamamLabel)
           contentView.addSubview(edamamDescriptionLabel)
           contentView.addSubview(dgChartsLabel)
           contentView.addSubview(dgChartsDescriptionLabel)
           
           // Set up constraints for scroll view and content view
           NSLayoutConstraint.activate([
               scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
               scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
               scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
               scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
               
               contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
               contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
               contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
               contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
               contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
           ])
           
           // Set up constraints for labels
           NSLayoutConstraint.activate([
               headingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
               headingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               headingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               
               descriptionLabel.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 16),
               descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               
               firebaseLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
               firebaseLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               firebaseLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               
               firebaseDescriptionLabel.topAnchor.constraint(equalTo: firebaseLabel.bottomAnchor, constant: 8),
               firebaseDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               firebaseDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               
               edamamLabel.topAnchor.constraint(equalTo: firebaseDescriptionLabel.bottomAnchor, constant: 32),
               edamamLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               edamamLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               
               edamamDescriptionLabel.topAnchor.constraint(equalTo: edamamLabel.bottomAnchor, constant: 8),
               edamamDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               edamamDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               
               dgChartsLabel.topAnchor.constraint(equalTo: edamamDescriptionLabel.bottomAnchor, constant: 32),
               dgChartsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               dgChartsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               
               dgChartsDescriptionLabel.topAnchor.constraint(equalTo: dgChartsLabel.bottomAnchor, constant: 8),
               dgChartsDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               dgChartsDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               dgChartsDescriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
           ])
       }
   }



/*

References:
- Apple Developer Documentation - [UILabel](https://developer.apple.com/documentation/uikit/uilabel) for creating and styling the labels.
- Apple Developer Documentation - [UIScrollView](https://developer.apple.com/documentation/uikit/uiscrollview) for implementing a scrollable view.
- Apple Developer Documentation - [UIStackView](https://developer.apple.com/documentation/uikit/uistackview) for arranging multiple labels vertically.
- Apple Developer Documentation - [UIFont](https://developer.apple.com/documentation/uikit/uifont) for setting custom fonts and sizes.
- Apple Developer Documentation - [NSLayoutConstraint](https://developer.apple.com/documentation/uikit/nslayoutconstraint) for defining Auto Layout constraints.
- Firebase Documentation - [Firebase](https://firebase.google.com) for backend services such as authentication, database, and analytics.
- Edamam API Documentation - [Edamam API](https://developer.edamam.com) for retrieving nutritional information and recipe data.
- DGCharts GitHub Repository - [DGCharts](https://github.com/DGChart) for creating charts and data visualizations.

*/
