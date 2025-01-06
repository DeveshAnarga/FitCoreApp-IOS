//  DiaryPageViewController.swift
//  FitCore
//
//  Created by Devesh Gurusinghe on 8/5/2024.
//
/*
 This view controller manages the diary page of the FitCore app. It displays a collection of user notes and images stored in Core Data.
 Users can enter editing mode to select and delete multiple images. The page includes functionality to fetch data from Core Data,
 handle long press gestures to toggle editing mode, and display images in a pop-up view.
*/

import UIKit
import FirebaseDatabase
import FirebaseAuth
import CoreData

class DiaryPageViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Array to store the notes fetched from Core Data
    var notes: [Note] = []
    
    // Array to store the images corresponding to the notes
    var images: [UIImage] = []
    
    // CollectionView to display the images
    var collectionView: UICollectionView!
    
    // Flag to indicate if the view controller is in editing mode
    var isEditingMode = false
    
    // Set to store the indices of the selected images in editing mode
    var selectedIndices: Set<Int> = []
    
    // MARK: - View Lifecycle
    
    // Called after the view has been loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI elements
        setupCollectionView()
        setupNavigationBar()
        
        // Fetch images from Core Data
        fetchImagesFromCoreData()
        
        // Add long press gesture recognizer to collectionView
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - UI Setup
    
    // This function sets up the collection view
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true // Allow multiple selection for editing mode
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
        view.addSubview(collectionView)
        
        // Add constraints to collectionView
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // This function sets up the navigation bar
    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(toggleEditingMode))
    }
    
    // MARK: - Long Press Gesture Handling
    
    // This function handles the long press gesture to toggle editing mode
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard !isEditingMode else { return }
        
        if gestureRecognizer.state == .began {
            toggleEditingMode()
        }
    }
    
    // MARK: - Core Data Operations
    
    // This function fetches images from Core Data
    func fetchImagesFromCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        
        do {
            notes = try context.fetch(fetchRequest)
            for note in notes {
                if let imageData = note.imageData, let image = UIImage(data: imageData) {
                    images.append(image)
                }
            }
            collectionView.reloadData()
        } catch {
            print("Failed to fetch images from Core Data: \(error.localizedDescription)")
        }
    }
    
    // This function deletes an image at the specified index path from Core Data and updates the collection view
    func deleteImage(at indexPath: IndexPath) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let note = notes[indexPath.item]
        context.delete(note)
        images.remove(at: indexPath.item)
        notes.remove(at: indexPath.item)
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
        
        collectionView.reloadData()
    }
    
    // MARK: - Button Actions
    
    // This function toggles the editing mode
    @objc func toggleEditingMode() {
        isEditingMode.toggle()
        navigationItem.rightBarButtonItem?.title = isEditingMode ? "Delete" : "Edit"
        if !isEditingMode {
            deleteSelectedImages()
        }
        collectionView.reloadData()
    }
    
    // This function deletes the selected images
    func deleteSelectedImages() {
        let selectedIndexes = Array(selectedIndices)
        selectedIndices.removeAll()
        
        let sortedIndexes = selectedIndexes.sorted(by: >) // Delete images from the last index to avoid index conflicts
        for index in sortedIndexes {
            let indexPath = IndexPath(item: index, section: 0)
            deleteImage(at: indexPath)
        }
        
        isEditingMode = false
        collectionView.reloadData()
        navigationItem.rightBarButtonItem?.title = "Edit" // Switch back to Edit
    }
    
    // MARK: - CollectionView Methods
    
    // This function returns the number of items in the collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    // This function configures and returns the cell for the specified index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell else {
            fatalError("Unable to dequeue ImageCollectionViewCell")
        }
        cell.imageView.image = images[indexPath.item]
        cell.isSelected = selectedIndices.contains(indexPath.item)
        cell.updateSelectionIndicator(isEditingMode: isEditingMode)
        return cell
    }
    
    // This function handles the selection of an item in the collection view
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditingMode {
            if selectedIndices.contains(indexPath.item) {
                selectedIndices.remove(indexPath.item)
            } else {
                selectedIndices.insert(indexPath.item)
            }
            collectionView.reloadItems(at: [indexPath])
        } else {
            // Show the image in a pop-up
            let image = images[indexPath.item]
            showImagePopUp(image)
        }
    }
    
    // This function sets the size for the items in the collection view
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacingBetweenCells: CGFloat = 10
        let totalSpacing = (numberOfColumns - 1) * spacingBetweenCells
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: width)
    }
    
    // MARK: - Image Pop-Up
    
    // This function shows the selected image in a pop-up
    private func showImagePopUp(_ image: UIImage) {
        let popUpViewController = UIAlertController(title: "Image", message: nil, preferredStyle: .alert)
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        popUpViewController.view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: popUpViewController.view.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: popUpViewController.view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: popUpViewController.view.trailingAnchor, constant: -20),
            imageView.bottomAnchor.constraint(equalTo: popUpViewController.view.bottomAnchor, constant: -60)
        ])
        
        let dismissButton = UIAlertAction(title: "Dismiss", style: .cancel) { _ in
            popUpViewController.dismiss(animated: true, completion: nil)
        }
        
        popUpViewController.addAction(dismissButton)
        
        present(popUpViewController, animated: true, completion: nil)
    }
}



/*
   References:
   - Apple Developer Documentation - UICollectionView: [UICollectionView](https://developer.apple.com/documentation/uikit/uicollectionview)
   - Apple Developer Documentation - Core Data: [Core Data](https://developer.apple.com/documentation/coredata)
   - Apple Developer Documentation - UILongPressGestureRecognizer: [UILongPressGestureRecognizer](https://developer.apple.com/documentation/uikit/uilongpressgesturerecognizer)
   - Apple Developer Documentation - UIAlertController: [UIAlertController](https://developer.apple.com/documentation/uikit/uialertcontroller)
   - Stack Overflow - Fetching Data from Core Data: [Stack Overflow](https://stackoverflow.com/questions/33397190/fetching-data-from-core-data)
   - Stack Overflow - Long Press Gesture in UICollectionView: [Stack Overflow](https://stackoverflow.com/questions/33815355/long-press-gesture-in-uicollectionview-cell)
   - Ray Wenderlich - Core Data Tutorial: [Ray Wenderlich](https://www.raywenderlich.com/7569-getting-started-with-core-data-tutorial)
   - YouTube - iOS Core Data Tutorial: [YouTube](https://www.youtube.com/watch?v=tuduIqt8Uu8)
   - YouTube - UICollectionView Tutorial: [YouTube](https://www.youtube.com/watch?v=OEDZZA2SoZs)
*/


















// ImageCollectionViewCell.swift
// FitCore
//
// Created by Devesh Gurusinghe on 8/5/2024.
//

/*
 This class defines a custom collection view cell used in the DiaryPageViewController.
 Each cell contains an image view and a selection indicator to show when the cell is selected in editing mode.
*/

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    // UIImageView to display the image
    var imageView: UIImageView!
    
    // UIImageView to display the selection indicator
    var selectionIndicator: UIImageView!
    
    // Initializer for programmatically created cells
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    // Initializer for cells created via storyboard or XIB
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Function to setup the UI elements of the cell
    private func setupUI() {
        // Setup the image view
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        // Setup the selection indicator
        selectionIndicator = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        selectionIndicator.isHidden = true
        selectionIndicator.tintColor = .systemBlue
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectionIndicator)
        
        // Add constraints to position the image view and selection indicator within the cell
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            selectionIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 25),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 25)
        ])
    }
    
    // Function to update the visibility of the selection indicator based on the editing mode status
    func updateSelectionIndicator(isEditingMode: Bool) {
        selectionIndicator.isHidden = !isEditingMode || !isSelected
    }
}

/*
   References:
   - Apple Developer Documentation - UICollectionViewCell: [UICollectionViewCell](https://developer.apple.com/documentation/uikit/uicollectionviewcell)
   - Apple Developer Documentation - UIImageView: [UIImageView](https://developer.apple.com/documentation/uikit/uiimageview)
   - Apple Developer Documentation - Auto Layout: [Auto Layout](https://developer.apple.com/documentation/uikit/nslayoutconstraint)
   - Stack Overflow - Custom UICollectionViewCell with Selection Indicator: [Stack Overflow](https://stackoverflow.com/questions/28650445/custom-uicollectionviewcell-with-selection-indicator)
   - Ray Wenderlich - UICollectionView Tutorial: Reusable Views: [Ray Wenderlich](https://www.raywenderlich.com/9334-uicollectionview-tutorial-reusable-views-selection-and-reordering)
   - YouTube - iOS UICollectionView Tutorial: [YouTube](https://www.youtube.com/watch?v=OEDZZA2SoZs)
*/
