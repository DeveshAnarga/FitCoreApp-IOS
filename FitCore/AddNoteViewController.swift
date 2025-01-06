
//  AddNoteViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 15/5/2024.
//

/*
 This view controller allows users to add notes with images to the FitCore app. Users can select an image from their photo library,
 preview it, and save it to Core Data. The view controller handles image picking, Core Data operations, and updating the UI based on the current interface style.
*/

import UIKit
import CoreData
import FirebaseAuth

class AddNoteViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Heading label for image upload
    let uploadHeadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Upload an image:"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        return label
    }()

    // Button for uploading images
    let uploadImageButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Choose Image", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 24
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
        button.addTarget(self, action: #selector(uploadImage), for: .touchUpInside)
        return button
    }()

    // Image view to preview uploaded image
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 1.0
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        return imageView
    }()

    // Save button
    let saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 24
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
        button.addTarget(self, action: #selector(saveNote), for: .touchUpInside)
        return button
    }()

    // Variable to hold the selected image
    var selectedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the background color
        view.backgroundColor = .systemBackground

        // Add subviews to the main view
        view.addSubview(uploadHeadingLabel)
        view.addSubview(uploadImageButton)
        view.addSubview(imageView)
        view.addSubview(saveButton)

        // Setup constraints for UI elements
        NSLayoutConstraint.activate([
            uploadHeadingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            uploadHeadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            uploadImageButton.topAnchor.constraint(equalTo: uploadHeadingLabel.bottomAnchor, constant: 24),
            uploadImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            imageView.topAnchor.constraint(equalTo: uploadImageButton.bottomAnchor, constant: 40),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            imageView.heightAnchor.constraint(equalToConstant: 200),

            saveButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        updateColorsForCurrentMode()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColorsForCurrentMode()
    }

    // MARK: - Image Upload

    // Function to handle the image upload process
    @objc func uploadImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }

    // MARK: - Save Note

    // Function to handle saving the note with the uploaded image
    @objc func saveNote() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let context = appDelegate.persistentContainer.viewContext
        let note = FitCore.Note(context: context) // Fully qualify the Note entity with its module name

        if let imageData = selectedImage?.jpegData(compressionQuality: 0.5) {
            note.imageData = imageData
        }

        // Set the current user's unique ID to the note
        if let currentUserID = getCurrentUserID() {
            note.userID = currentUserID
        }

        do {
            try context.save()
            print("Note saved successfully!")
            
            // Clear the image view and selected image
            selectedImage = nil
            imageView.image = nil

            // Show success alert
            let alert = UIAlertController(title: "Success", message: "Image successfully added to gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
        } catch {
            print("Failed to save note: \(error.localizedDescription)")
        }
    }

    // Function to get the current user's unique ID
    func getCurrentUserID() -> String? {
        // Implement the logic to retrieve the user's unique ID from Firebase Authentication
        if let currentUser = Auth.auth().currentUser {
            return currentUser.uid
        } else {
            return nil
        }
    }

    // MARK: - UIImagePickerControllerDelegate

    // Function to handle the selection of an image from the photo library
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImage = pickedImage
            imageView.image = pickedImage
        }

        dismiss(animated: true, completion: nil)
    }

    // Function to handle the cancellation of the image picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    // Function to update the colors of UI elements based on the current interface style
    private func updateColorsForCurrentMode() {
        let currentMode = traitCollection.userInterfaceStyle
        if (currentMode == .dark) {
            uploadHeadingLabel.textColor = .white
            imageView.layer.borderColor = UIColor.white.cgColor
        } else {
            uploadHeadingLabel.textColor = .black
            imageView.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
}

/*
   References:
   - Apple Developer Documentation - UIImagePickerController: [UIImagePickerController](https://developer.apple.com/documentation/uikit/uiimagepickercontroller)
   - Apple Developer Documentation - Core Data: [Core Data](https://developer.apple.com/documentation/coredata)
   - Apple Developer Documentation - Firebase Authentication: [FirebaseAuth](https://firebase.google.com/docs/auth)
   - Apple Developer Documentation - UIAlertController: [UIAlertController](https://developer.apple.com/documentation/uikit/uialertcontroller)
   - Apple Developer Documentation - Auto Layout: [Auto Layout](https://developer.apple.com/documentation/uikit/nslayoutconstraint)
   - Stack Overflow - Save UIImage in Core Data: [Stack Overflow](https://stackoverflow.com/questions/27567909/save-uiimage-in-core-data)
   - YouTube - UIImagePickerController Tutorial: [YouTube](https://www.youtube.com/watch?v=EoeLHB1pN8I)
   - Ray Wenderlich - Core Data Tutorial: [Ray Wenderlich](https://www.raywenderlich.com/7569-getting-started-with-core-data-tutorial)
   - Medium - Firebase Authentication with Swift: [Medium](https://medium.com/firebase-developers/firebase-authentication-in-swift-52d5a5c7047d)
*/

