//  InitalDiaryViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 16/5/2024.
//
/*
 This view controller displays the initial diary page of the FitCore app.
 It shows a random image from the user's gallery and the total count of images stored in Core Data.
 The view updates the displayed image and the total count each time it appears.
*/


import UIKit
import CoreData

class InitalDiaryViewController: UIViewController {
    
    // Outlet for the image view that displays a random image from the gallery
    @IBOutlet weak var RecentGalleryImage: UIImageView!
    
    
    // Outlet for the label that displays the total number of images in the gallery
    @IBOutlet weak var TotalImages: UILabel!
    
    
    // MARK: - View Lifecycle
        
        // Called after the view has been loaded
        override func viewDidLoad() {
            super.viewDidLoad()
            fetchRandomImage() // Fetch a random image from Core Data
            fetchTotalImagesCount() // Fetch the total count of images from Core Data
        }
        
        // Called just before the view appears on the screen
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            fetchTotalImagesCount() // Update the total images count when the view appears
            fetchRandomImage() // Update the random image when the view appears
        }
        
        // MARK: - Core Data Operations
        
        // Function to fetch a random image from Core Data
        func fetchRandomImage() {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
            
            do {
                let notes = try context.fetch(fetchRequest)
                if let randomNote = notes.randomElement(), let imageData = randomNote.imageData {
                    clearDefaultImage() // Clear the default image
                    RecentGalleryImage.image = UIImage(data: imageData) // Set the random image
                } else {
                    showDefaultImage() // Show the default image if no random image is found
                }
            } catch {
                print("Failed to fetch image from Core Data: \(error.localizedDescription)")
                showDefaultImage() // Show the default image if fetching fails
            }
        }
        
        // Function to fetch the total count of images from Core Data
        func fetchTotalImagesCount() {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
            
            do {
                let totalCount = try context.count(for: fetchRequest)
                TotalImages.text = "Total Images: \(totalCount)" // Update the total images count
            } catch {
                print("Failed to fetch total images count from Core Data: \(error.localizedDescription)")
            }
        }
        
        // Function to show a default image when no images are available
        func showDefaultImage() {
            RecentGalleryImage.backgroundColor = .lightGray
            RecentGalleryImage.image = nil
            let label = UILabel(frame: RecentGalleryImage.bounds)
            label.text = "No Image Available"
            label.textAlignment = .center
            label.textColor = .darkGray
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            RecentGalleryImage.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: RecentGalleryImage.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: RecentGalleryImage.centerYAnchor),
                label.widthAnchor.constraint(equalTo: RecentGalleryImage.widthAnchor),
                label.heightAnchor.constraint(equalTo: RecentGalleryImage.heightAnchor)
            ])
        }
        
        // Function to clear the default image
        func clearDefaultImage() {
            RecentGalleryImage.backgroundColor = .clear
            RecentGalleryImage.image = nil
            for subview in RecentGalleryImage.subviews {
                subview.removeFromSuperview() // Remove any subviews (e.g., the default label)
            }
        }
    }

    /*
       References:
       - Apple Developer Documentation - UIImageView: [UIImageView](https://developer.apple.com/documentation/uikit/uiimageview)
       - Apple Developer Documentation - UILabel: [UILabel](https://developer.apple.com/documentation/uikit/uilabel)
       - Apple Developer Documentation - Core Data: [Core Data](https://developer.apple.com/documentation/coredata)
       - Apple Developer Documentation - NSLayoutConstraint: [NSLayoutConstraint](https://developer.apple.com/documentation/uikit/nslayoutconstraint)
       - Stack Overflow - Fetching Data from Core Data: [Stack Overflow](https://stackoverflow.com/questions/33397190/fetching-data-from-core-data)
       - Ray Wenderlich - Core Data Tutorial: [Ray Wenderlich](https://www.raywenderlich.com/7569-getting-started-with-core-data-tutorial)
       - YouTube - Core Data Tutorial: [YouTube](https://www.youtube.com/watch?v=rjTaOHX5FNE)
       - YouTube - UIImageView Tutorial: [YouTube](https://www.youtube.com/watch?v=nKGJGP-cX9I)
    */







