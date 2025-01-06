/*
 SettingsViewController.swift
 FitCore
 
 Created by Devesh Gurusinghe on 8/6/2024.
 
 Description:
 This view controller manages the settings screen where users can update their fitness information, view app-related details, and provide feedback. It displays a list of sections such as "Update Fitness Info", "About", and "Feedback", each leading to a corresponding view controller for more detailed actions.
 
 Functionality:
 - Displays a heading label "Settings" at the top of the screen.
 - Presents a table view with sections for different settings options.
 - Each section corresponds to a specific action or view.
 - Allows navigation to different sections upon tapping the table view cells.
 

*/

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
       
       // TableView for displaying settings options
       private let tableView = UITableView(frame: .zero, style: .plain)
       
       // Heading label
       private let headingLabel: UILabel = {
           let label = UILabel()
           label.text = "Settings"
           label.font = UIFont(name: "Geeza Pro Bold", size: 32)
           label.textAlignment = .center
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       // Sections for settings options
       private let sections: [Section] = [.updateFitnessInfo, .about, .feedback]
       
       // MARK: - Section Enum
       
       // Enum to represent different sections in the settings
       enum Section: Int, CaseIterable {
           case updateFitnessInfo
           case about
           case feedback
           
           // Title for each section
           var title: String {
               switch self {
               case .updateFitnessInfo: return "Update Fitness Info"
               case .about: return "About"
               case .feedback: return "Feedback"
               }
           }
           
           // Storyboard identifier for each section
           var storyboardID: String {
               switch self {
               case .updateFitnessInfo: return "UpdateFitnessInfoVC"
               case .about: return "AboutVC"
               case .feedback: return "FeedbackVC"
               }
           }
       }
       
       // MARK: - View Lifecycle
       
       override func viewDidLoad() {
           super.viewDidLoad()
           
           // Set up the view controller
           self.view.backgroundColor = .systemBackground
           
           // Set up heading label
           view.addSubview(headingLabel)
           
           // Set up table view
           setupTableView()
           
           // Customize navigation bar appearance
           customizeNavigationBarAppearance()
       }
       
       // MARK: - Table View Setup
       
       // Configure table view properties and register cells
       private func setupTableView() {
           tableView.dataSource = self
           tableView.delegate = self
           tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
           tableView.translatesAutoresizingMaskIntoConstraints = false
           tableView.separatorStyle = .singleLine
           tableView.separatorColor = .systemGray
           view.addSubview(tableView)
           
           // Set up constraints
           NSLayoutConstraint.activate([
               headingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
               headingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
               headingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
               
               tableView.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 32),
               tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
               tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
               tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
           ])
       }
       
       // MARK: - Navigation Bar Customization
       
       // Customize navigation bar appearance
       private func customizeNavigationBarAppearance() {
           if let navigationBar = navigationController?.navigationBar {
               let appearance = UINavigationBarAppearance()
               appearance.configureWithOpaqueBackground()
               appearance.backgroundColor = .systemBackground
               appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
               
               navigationBar.standardAppearance = appearance
               navigationBar.scrollEdgeAppearance = appearance
           }
       }
       
       // MARK: - UITableViewDataSource
       
       // Number of sections in table view
       func numberOfSections(in tableView: UITableView) -> Int {
           return 1
       }

       // Number of rows in each section
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return sections.count
       }

       // Configure table view cells
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
           let section = sections[indexPath.row]
           cell.textLabel?.text = section.title
           cell.accessoryType = .disclosureIndicator
           cell.textLabel?.font = UIFont(name: "Geeza Pro Bold", size: 16)
           cell.textLabel?.textColor = .label
           return cell
       }
       
       // MARK: - UITableViewDelegate
       
       // Handle row selection
       func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           tableView.deselectRow(at: indexPath, animated: true)
           let section = sections[indexPath.row]
           navigateToSection(section)
       }
       
       // MARK: - Navigation
       
       // Navigate to selected section
       private func navigateToSection(_ section: Section) {
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           let viewController = storyboard.instantiateViewController(withIdentifier: section.storyboardID)
           viewController.view.backgroundColor = .systemBackground
           viewController.title = section.title
           navigationController?.pushViewController(viewController, animated: true)
       }
   }


/*
 References:
 - Apple Developer Documentation - [UITableView](https://developer.apple.com/documentation/uikit/uitableview)
 - Apple Developer Documentation - [UILabel](https://developer.apple.com/documentation/uikit/uilabel)
 - Apple Developer Documentation - [UINavigationBar](https://developer.apple.com/documentation/uikit/uinavigationbar)
 - Stack Overflow - [iOS Development](https://stackoverflow.com/questions/tagged/ios)
*/

