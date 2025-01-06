
/*  
 NutritionPageViewController.swift
 FitCore

  Created by Devesh Gurusinghe on 5/4/2024.

 This view controller manages the nutrition page of the FitCore app. It allows users to search for food items,view detailed nutritional information, and see images of the selected food items. The page integrates with the Edamam API to fetch comprehensive food data, including calorie count, protein, fat, and carbohydrate content. Users can interact with the search bar to find specific foods and view their nutritional profiles in an intuitive and user-friendly interface.

 */


import UIKit

class NutritionPageViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets for Food Information
   
    @IBOutlet weak var Foodimage: UIImageView!
    @IBOutlet weak var Foodname: UILabel!
    @IBOutlet weak var NumberofCalories: UILabel!
    
    //Slider + grams (Protein,Carbs,Fats)
    @IBOutlet weak var CarbAmount: UISlider!
    @IBOutlet weak var Carbgrams: UILabel!
    @IBOutlet weak var ProteinAmount: UISlider!
    @IBOutlet weak var Proteingrams: UILabel!
    @IBOutlet weak var FatAmount: UISlider!
    @IBOutlet weak var Fatgrams: UILabel!
    
    
    // MARK: - Properties for Search and Results
    
    var tableView: UITableView!
    var foodSearchBar: UISearchBar!
    var loadingIndicator: UIActivityIndicatorView!
    
    // Arrays to store search results
    var similarFoods: [EdamamFood] = []
    var imageUrls: [URL] = []
        
    
    // MARK: - Edamam API Credentials
    
    let edamamAppId = "4621b92b"
    let edamamAppKey = "8517e4a8814bf6216dea106329872817"
    
    
    
    
    // MARK: - View Lifecycle
    // This function is called after the view has been loaded into memory.
    // It is used to perform any additional setup required for the view.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the Food image view to have rounded corners.
        Foodimage.layer.cornerRadius = 30
        Foodimage.layer.masksToBounds = true

        // Disable the sliders initially to prevent user interaction.
        CarbAmount.isUserInteractionEnabled = false
        ProteinAmount.isUserInteractionEnabled = false
        FatAmount.isUserInteractionEnabled = false

        // Call setup methods to configure the UI elements.
        setupSearchBar()
        setupTableView()
        setupLoadingIndicator()
    }


    // MARK: - Setup Methods
    // This function sets up the search bar used to search for food items.
    func setupSearchBar() {
        // Create and configure the UISearchBar.
        foodSearchBar = UISearchBar()
        foodSearchBar.placeholder = "Search for food"
        foodSearchBar.delegate = self
        view.addSubview(foodSearchBar)
        
        // Add layout constraints to position the search bar at the top of the view.
        foodSearchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            foodSearchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            foodSearchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            foodSearchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // This function sets up the table view used to display search results.
    func setupTableView() {
        // Create and configure the UITableView.
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        // Add layout constraints to position the table view below the search bar.
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: foodSearchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Hide the table view initially.
        tableView.isHidden = true
    }

    // This function sets up the loading indicator shown while fetching data.
    func setupLoadingIndicator() {
        // Create and configure the UIActivityIndicatorView.
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        // Add layout constraints to center the loading indicator on the screen.
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - UISearchBarDelegate Methods
    // This function is called when the search button on the keyboard is tapped.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Dismiss the keyboard.
        searchBar.resignFirstResponder()
        
        // Start searching for food items if the query is not empty.
        if let query = searchBar.text, !query.isEmpty {
            loadingIndicator.startAnimating()
            searchFood(query: query, maxResults: 10)
        }
    }

    // MARK: - API Request
    // This function sends a request to the Edamam API to search for food items based on the user's query.
    func searchFood(query: String, maxResults: Int = 10) {
        // Ensure the query is properly URL encoded to handle spaces and special characters.
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.edamam.com/api/food-database/v2/parser?ingr=\(encodedQuery)&app_id=\(edamamAppId)&app_key=\(edamamAppKey)") else {
            print("Invalid URL")
            return
        }

        // Fetch food data from the Edamam API.
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Handle any errors that occurred during the network request.
            if let error = error {
                print("Error: \(error)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                }
                return
            }

            // Ensure data was received from the network request.
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                }
                return
            }

            do {
                // Decode the JSON response to extract food data.
                let decoder = JSONDecoder()
                let searchResponse = try decoder.decode(EdamamSearchResponse.self, from: data)

                // Update the UI with the search results on the main thread.
                DispatchQueue.main.async {
                    self.updateUI(with: Array(searchResponse.hints.prefix(maxResults)).map { $0.food })
                    self.loadingIndicator.stopAnimating()
                }
            } catch {
                // Handle any errors that occurred while decoding the JSON response.
                print("Error decoding JSON: \(error)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                }
            }
        }.resume()
    }

    // MARK: - Update UI with API Results
    func updateUI(with foods: [EdamamFood]) {
        similarFoods = foods
        tableView.reloadData()
        tableView.isHidden = false
    }

    // MARK: - Load Image for Selected Food
    // This function fetches an image for the selected food item using the Edamam API.
    func loadImage(from query: String) {
        // Ensure the query is properly URL encoded to handle spaces and special characters.
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.edamam.com/api/food-database/v2/parser?ingr=\(encodedQuery)&app_id=\(edamamAppId)&app_key=\(edamamAppKey)") else {
            print("Invalid URL")
            return
        }

        // Start the loading indicator to show that an image is being fetched.
        loadingIndicator.startAnimating()

        // Reset the Food image view by clearing the image and background color, and removing any subviews.
        Foodimage.image = nil
        Foodimage.backgroundColor = nil
        Foodimage.subviews.forEach { $0.removeFromSuperview() }

        // Perform the network request to fetch the image data.
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Handle any errors that occurred during the network request.
            if let error = error {
                print("Error fetching image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.showDefaultImage() // Show a default image if there was an error.
                }
                return
            }

            // Ensure data was received from the network request.
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.showDefaultImage() // Show a default image if no data was received.
                }
                return
            }

            do {
                // Decode the JSON response to extract the image URL.
                let decoder = JSONDecoder()
                let imageResponse = try decoder.decode(EdamamSearchResponse.self, from: data)
                guard let imageUrl = URL(string: imageResponse.hints.first?.food.image ?? "") else {
                    print("No image URL found")
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                        self.showDefaultImage() // Show a default image if no image URL was found.
                    }
                    return
                }

                // Download the image using the extracted image URL.
                URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                    }

                    // Handle any errors that occurred while downloading the image.
                    guard let data = data, error == nil else {
                        print("Error fetching image: \(error?.localizedDescription ?? "Unknown error")")
                        DispatchQueue.main.async {
                            self.showDefaultImage() // Show a default image if there was an error.
                        }
                        return
                    }

                    // Set the downloaded image to the Foodimage view if the image data is valid.
                    if let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.Foodimage.image = image
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showDefaultImage() // Show a default image if the image data is invalid.
                        }
                    }
                }.resume()
            } catch {
                // Handle any errors that occurred while decoding the JSON response.
                print("Error decoding JSON: \(error)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.showDefaultImage() // Show a default image if there was an error decoding the JSON.
                }
            }
        }.resume()
    }
                                

       
    // MARK: - Display Default Image
    // This function displays a default image and message when no image is available for the selected food item.
    func showDefaultImage() {
        // Set the background color of the Foodimage view to light gray.
        Foodimage.backgroundColor = UIColor.lightGray
        
        // Create and configure a UILabel to display a "No image available" message.
        let label = UILabel(frame: Foodimage.bounds)
        label.text = "No image available"
        label.textAlignment = .center
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        
        // Add the label to the Foodimage view.
        Foodimage.addSubview(label)
    }


    // MARK: - UISearchBarDelegate Method
    // This method is called whenever the text in the search bar changes.
    // Currently, it does nothing to only show suggestions when the search button is clicked.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Do nothing on text change to only show suggestions on search button click
    }

    // MARK: - UITableViewDataSource Methods
    // This method returns the number of rows in the table view's section, which is equal to the number of similar foods found.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return similarFoods.count
    }

    // This method configures and returns a cell for the given row at the specified index path.
    // It sets the text label of the cell to the label of the corresponding food item.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let food = similarFoods[indexPath.row]
        cell.textLabel?.text = food.label
        return cell
    }

    // MARK: - UITableViewDelegate Method
    // This method is called when a row in the table view is selected.
    // It updates the UI with the details of the selected food item.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get the selected food item from the array of similar foods.
        let selectedFood = similarFoods[indexPath.row]
        
        // Update the UI labels with the selected food's name and nutritional information.
        Foodname.text = selectedFood.label
        NumberofCalories.text = "\(selectedFood.nutrients.ENERC_KCAL ?? 0.0) kcal"
        
        // Extract protein, fat, and carbohydrate amounts from the selected food's nutrients.
        let protein = selectedFood.nutrients.PROCNT ?? 0.0
        let fat = selectedFood.nutrients.FAT ?? 0.0
        let carbohydrate = selectedFood.nutrients.CHOCDF ?? 0.0
        
        // Update the UI labels with the extracted nutrient values.
        Proteingrams.text = String(format: "%.1f G", protein)
        Fatgrams.text = String(format: "%.1f G", fat)
        Carbgrams.text = String(format: "%.1f G", carbohydrate)
        
        // Smooth transition for slider values to reflect the new nutrient amounts.
        let duration: TimeInterval = 2.0
        let steps: Int = 100
        
        // Calculate the step values for the sliders to create a smooth animation.
        let proteinStep = (protein - ProteinAmount.value) / Float(steps)
        let fatStep = (fat - FatAmount.value) / Float(steps)
        let carbStep = (carbohydrate - CarbAmount.value) / Float(steps)
        
        // Animate the slider values incrementally.
        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (duration / Double(steps)) * Double(step)) {
                self.ProteinAmount.value += proteinStep
                self.FatAmount.value += fatStep
                self.CarbAmount.value += carbStep
            }
        }
        
        // Hide the table view and clear the search bar text.
        tableView.isHidden = true
        foodSearchBar.text = ""
        
        // Load the image for the selected food item.
        loadImage(from: selectedFood.label)
    }

    }

// MARK: - Models for JSON Response
// These structures are used to decode the JSON response from the Edamam API.

// The top-level response structure which contains an array of hints.
struct EdamamSearchResponse: Codable {
    let hints: [Hint]
}

// Each hint contains a food item.
struct Hint: Codable {
    let food: EdamamFood
}

// The structure representing a food item, including its label, image URL, and nutritional information.
struct EdamamFood: Codable {
    let label: String // The name of the food item.
    let image: String? // Optional URL string for the food item's image.
    let nutrients: Nutrients // The nutrients associated with the food item.
}

// The structure representing the nutrients of a food item.
struct Nutrients: Codable {
    let ENERC_KCAL: Float? // Energy in kilocalories.
    let PROCNT: Float? // Protein content in grams.
    let FAT: Float? // Fat content in grams.
    let CHOCDF: Float? // Carbohydrate content in grams.
}


/*
References:
- Apple Developer Documentation - URL Encoding: [URL Encoding](https://developer.apple.com/documentation/foundation/nsurl/1406545-addingpercentencoding)
- Apple Developer Documentation - URLSession: [URLSession](https://developer.apple.com/documentation/foundation/urlsession)
- Apple Developer Documentation - JSONDecoder: [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder)
- Handling JSON Data in Swift: [Handling JSON](https://developer.apple.com/documentation/foundation/jsondecoder)
- Edamam API Documentation: [Edamam API](https://developer.edamam.com/)
- Apple Developer Documentation for UISearchBar: [UISearchBar](https://developer.apple.com/documentation/uikit/uisearchbar)
- Apple Developer Documentation for UITableView: [UITableView](https://developer.apple.com/documentation/uikit/uitableview)
- Apple Developer Documentation for UIImageView: [UIImageView](https://developer.apple.com/documentation/uikit/uiimageview)
- Stack Overflow - Handling JSON Data: [Stack Overflow](https://stackoverflow.com/questions/24410881/handling-json-data-in-swift)
- YouTube - Working with URLSession: [YouTube](https://www.youtube.com/watch?v=rjxC4V1TCm8)
- Medium - Working with JSON in Swift: [Medium](https://medium.com/@felixdumit/working-with-json-in-swift-753b4ba78441)
- Ray Wenderlich - Networking in Swift with URLSession: [Ray Wenderlich](https://www.raywenderlich.com/3244963-urlsession-tutorial-getting-started)
*/

