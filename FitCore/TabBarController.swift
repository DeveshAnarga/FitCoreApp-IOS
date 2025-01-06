//
//  TabBarController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 15/5/2024.

//TabBarController is a subclass of UITabBarController responsible for managing the main tab-based navigation interface of the FitCore app. It customizes the behavior of the tab bar controller, such as hiding the back button in the navigation bar, and provides hooks for navigation-related events.

import UIKit

class TabBarController: UITabBarController {
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the back button in the navigation bar
        navigationItem.hidesBackButton = true
    }
    
    
}


/*

References:
- Apple Developer Documentation - [UITabBarController](https://developer.apple.com/documentation/uikit/uitabbarcontroller) for managing a tab bar interface and coordinating the navigation of content between different view controllers.
- Apple Developer Documentation - [UINavigationController](https://developer.apple.com/documentation/uikit/uinavigationcontroller) for managing the navigation of hierarchical content.
*/
