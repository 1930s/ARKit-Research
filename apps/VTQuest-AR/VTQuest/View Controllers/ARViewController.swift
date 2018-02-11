//
//  ARViewController.swift
//  VT AR Tour
//
//  Created by Patrick Gatewood on 10/31/17.
//  Copyright © 2017 Patrick Gatewood. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation

class ARViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate, BuildingDetailsDelegate, UIGestureRecognizerDelegate {
    
    // Sets the status bar to light mode
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBOutlet var sceneView: ARSCNView!
    
    let vtBuildingsWSBaseUrl: String = "http://orca.cs.vt.edu/VTBuildingsJAX-RS/webresources/vtBuildings"
    
    // JSON read from the Document directory (cache)
    var jsonInDocumentDirectory: Data? = nil
    
    // Opacity for all BuildingDetails overlays
    let buildingDetailsOverlayOpacity: CGFloat = 0.92
    
    // A strong reference to CLLocationManager is required by the CoreLocation API
    var locationManager = CLLocationManager()
    
    // Dictionary mapping SCNNodes to their backing Building dictionaries
    var dict_LabelNode_BuildingDict: NSMutableDictionary = NSMutableDictionary()
    
    var backButton: UIImageView = UIImageView(image: UIImage(named: "back-icon"))
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        
        // Required for "swipe right to go back" gesture with a hidden navigation bar
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        // User must enable location services to use this app
        if !CLLocationManager.locationServicesEnabled() {
            showAlertMessage(title: "Location Services Disabled", message: "You must enable location services to use this app")
            return
        }
        
        // Set up gesture recognizers
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ARViewController.userTappedScreen(_:)))
         tapGestureRecognizer.cancelsTouchesInView = false // Pass touches through to subviews
        
        // Add gesture recognizers to the view
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Get the user's location
        locationManager.requestWhenInUseAuthorization()
        getLocation()
        
        // Display a hint for a few seconds
        sceneView.overlaySKScene = createOverlayHintLabel(withText: "Tap a building or walk closer to display more information.")
        fadeNodeInAndOut(node: sceneView.overlaySKScene!, initialDelay: 2.0, fadeInDuration: 1.0, displayDuration: 6.0, fadeOutDuration: 1.0)
    }
    
    // Creates an overlay containing a label with hint text and a translucent background
    func createOverlayHintLabel(withText: String) -> SKScene {
        // Create an overlay banner to be positioned in the middle of the SceneView.
        let overlayScene = SKScene(size: sceneView.bounds.size)
        overlayScene.scaleMode = .resizeFill
        
        // Configure the hint label
        let hintLabel = SKLabelNode(text: withText)
        hintLabel.fontSize = 40
        hintLabel.verticalAlignmentMode = .center
        hintLabel.preferredMaxLayoutWidth = overlayScene.size.width
        hintLabel.numberOfLines = 2
        hintLabel.lineBreakMode = .byWordWrapping
        
        // Configure the label background
        let labelBackground = SKShapeNode()
        
        // Give the background a slightly larger bounding rectangle in order to give the text a margin.
        let labelBackgroundSizeRect = hintLabel.frame.insetBy(dx: -10, dy: -10)
        labelBackground.path = CGPath(roundedRect: labelBackgroundSizeRect, cornerWidth: 5, cornerHeight: 5, transform: nil)
        labelBackground.position = CGPoint(x: sceneView.frame.midX, y: sceneView.frame.midY)
        labelBackground.strokeColor = UIColor.clear
        labelBackground.fillColor = UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.96)
        labelBackground.addChild(hintLabel)
        
        // Add the overlay and its contents to the scene.
        overlayScene.addChild(labelBackground)
        overlayScene.alpha = 0
        
        return overlayScene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        
        // Defines the ARSession's coordinate system based on gravity and the compass heading in the device. Note: THIS IS CRITICALLY IMPORTANT for location-based AR applications
        configuration.worldAlignment = .gravityAndHeading
        
        // Hide navigation and tab bars to prevent disrupting the AR user experience
        navigationController?.isNavigationBarHidden = true
        tabBarController?.tabBar.isHidden = true
        
        // Provide the user with a visual back button.
        setupBackButton()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    // Creates a back button and adds it to the scene
    func setupBackButton() {
        // Position the button right under the status bar
        backButton.frame = CGRect(x: 25, y: 40, width: 35, height: 35)
        view.addSubview(backButton)
        
        // Fade out the back button after a few seconds.
        UIView.animateKeyframes(withDuration: 1.0, delay: 6.0, options: .allowUserInteraction, animations: {
            self.backButton.alpha = 0
        }, completion: { (finished: Bool) in
            self.backButton.isHidden = true
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigatio and tab bars
        navigationController?.isNavigationBarHidden = false
        tabBarController?.tabBar.isHidden = false
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        showAlertMessage(title: "AR Session failed!", message: "Here's what went wrong: \(error.localizedDescription)")
    }
    
    // MARK: - Location Methods

    // Gets the user's location and reports all device movement
    func getLocation() {
        // The user has not authorized location monitoring
        if (CLLocationManager.authorizationStatus() == .denied) {
            showAlertMessage(title: "App Not Authorized", message: "Unable to determine your location: please allow VT AR Tour to use your location.")
            
            // Try to get location authorization again
            locationManager.requestWhenInUseAuthorization()
            
            return
        }
        
        locationManager.delegate = self
        
        // Report ALL device movement
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Get the highest possible degree of accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    // MARK: CLLocationManager Delegate

    // New location data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //  Must wait until at least one heading update comes through. If we proceed before this, our coordinate system won't be set up correctly
        guard (manager.heading?.magneticHeading) != nil else { return }
        
        // Don't process any further without the user's current location
        guard let currentLocation: CLLocation = locations.last else { return }
        
        // Fetch the VT Buildings JSON if necessary
        if jsonInDocumentDirectory == nil {
            jsonInDocumentDirectory = getVTBuildingsJSON()
        }
        
        if let jsonDataFromApi = jsonInDocumentDirectory {
            // Getting the JSON was successful
            do {
                let jsonArray = try JSONSerialization.jsonObject(with: jsonDataFromApi, options: .mutableContainers) as! NSArray
                
                for building in jsonArray {
                    processBuilding(building, currentLocation)
                }
            } catch let error as NSError {
                showAlertMessage(title: "Error in JSON serialization", message: error.localizedDescription)
            }
        }
    }
    
    /*
     * Creates a building dictionary, computes the building's location in the SceneView,
     * and displays appropriate data about the building
     */
    func processBuilding(_ building: Any, _ currentLocation: CLLocation) {
        let buildingDict = building as! NSMutableDictionary
        let buildingLocation: CLLocation = CLLocation(latitude: buildingDict["latitude"]! as! CLLocationDegrees, longitude: buildingDict["longitude"]! as! CLLocationDegrees)
        
        // Compute the distance between the user's current location and the building's location
        let distanceFromUserInMiles: Double = distanceBetweenPointsInMiles(lat1: currentLocation.coordinate.latitude, long1: currentLocation.coordinate.longitude, lat2: buildingLocation.coordinate.latitude, long2: buildingLocation.coordinate.longitude)
        
        // Disregard buildings that are too far away to accurately display
        if (distanceFromUserInMiles >= 0.25) {
            return
        }
        
        // Record how far the building is from the user.
        buildingDict["distanceFromUser"] = distanceFromUserInMiles
        
        // Create a building label node and record it and its related dictionary in another dictionary
        let labelNode: SCNNode = createBuildingLabelNode(currentLocation, buildingLocation, distanceFromUserInMiles, buildingDict: buildingDict)
        dict_LabelNode_BuildingDict[labelNode.name!] = buildingDict
        
        // If the user is close to the building, create a BuildingDetailsView embedded in a SCNNode
        let detailsMaxDistance = 0.1 // miles
        var buildingDetailsPlaneNode: SCNNode? = nil
        let buildingDetailsNodeName = "\(labelNode.name!)-detailsNode"
        if distanceFromUserInMiles <= detailsMaxDistance, let buildingDict: NSMutableDictionary = dict_LabelNode_BuildingDict[labelNode.name!] as? NSMutableDictionary {
            buildingDetailsPlaneNode = createPopulatedBuildingDetailsSCNNode(buildingDict: buildingDict, anchor: labelNode.position)
            buildingDetailsPlaneNode?.name = buildingDetailsNodeName
        }
        
        // Check if the building label and the building details are already rendered in the scene
        let existingBuildingLabelNode = sceneView.scene.rootNode.childNode(withName: labelNode.name!, recursively: false)
        let existingBuildingDetailsNode = sceneView.scene.rootNode.childNode(withName: buildingDetailsNodeName, recursively: false)
        
        // Display the appropriate SCNNode depending on the building's distance from the user
        if (existingBuildingLabelNode == nil) {
            // Add the building label to the scene
            sceneView.scene.rootNode.addChildNode(labelNode)
        } else if (existingBuildingDetailsNode == nil && buildingDetailsPlaneNode != nil) {
            // User got closer: fade out the building name and fade in the building details
            buildingDetailsPlaneNode!.opacity = 0
            sceneView.scene.rootNode.addChildNode(buildingDetailsPlaneNode!)
            crossFadeNodes(fadeInNode: buildingDetailsPlaneNode!, fadeOutNode: existingBuildingLabelNode!, duration: 1.0)
        } else if distanceFromUserInMiles > detailsMaxDistance && existingBuildingLabelNode != nil && existingBuildingDetailsNode != nil {
            // User moved away: fade out the building details and fade in the building name
            crossFadeNodes(fadeInNode: existingBuildingLabelNode!, fadeOutNode: existingBuildingDetailsNode!, duration: 1.0)
        }
    }
    
    // MARK: - JSON Methods
    
    // Gets the VT Buildings JSON from the device's cache or from the API
    func getVTBuildingsJSON() -> Data? {
        do {
            // Try to read the JSON from the device's Document directory
            jsonInDocumentDirectory = getJsonInDocumentDirectory(jsonFileName: "VTBuildings.plist")
            
            if jsonInDocumentDirectory != nil {
                // Successfully read cached data
                return jsonInDocumentDirectory
            } else {
                // Reading cached data failed; download JSON data from the API in a single thread
                let jsonData: Data? = try Data(contentsOf: URL(string: vtBuildingsWSBaseUrl)!, options: NSData.ReadingOptions.dataReadingMapped)
                    // Save the data we just downloaded from the API
                if let jsonDataFromApi = jsonData {
                    writeJsonDataToDocumentDirectory(jsonData: jsonDataFromApi, jsonFileName: "VTBuildings.plist")
                }
                
                return jsonData
            }
        } catch let error as NSError {
            showAlertMessage(title: "HTTP error", message: "Error getting VT Building data from the server: \(error.localizedDescription)")
        }
        
        return jsonInDocumentDirectory
    }
    
    // MARK: Reading/Writing JSON from Document directory
    
    // Returns an optional Data object holding the contents of the JSON file in the Document directory.
    func getJsonInDocumentDirectory(jsonFileName: String) -> Data? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectoryPath = paths[0] as String
        
        do {
            let jsonObject = try Data(contentsOf: URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(jsonFileName), options: NSData.ReadingOptions.dataReadingMapped)
            return jsonObject
        } catch _ as NSError{
            return nil
        }
    }
    
    // Saves json data to the given filename in the Document directory
    func writeJsonDataToDocumentDirectory(jsonData: Data, jsonFileName: String) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectoryPath = paths[0] as String
        
        do {
            try jsonData.write(to: URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(jsonFileName), options: .atomicWrite)
        } catch let error as NSError {
            showAlertMessage(title: "Caching JSON data failed!", message: "Error: \(error.localizedDescription)")
        }
    }
    
    // MARK - Create Building Labels
    
    // Creates a SCNNode that displays the building's name
    func createBuildingLabelNode(_ currentLocation: CLLocation, _ buildingLocation: CLLocation, _ distanceFromUserInMiles: Double, buildingDict: NSMutableDictionary) -> SCNNode {
        
        // Add a marker in the building's position
        let buildingARLocation: matrix_float4x4 = getARCoordinateOfBuilding(userLocation: currentLocation, buildingLocation: buildingLocation, distanceFromUserInMiles: distanceFromUserInMiles)
        let buildingARLocationPositionColumn = buildingARLocation.columns.3
        let targetPosition: SCNVector3 = SCNVector3Make(buildingARLocationPositionColumn.x, buildingARLocationPositionColumn.y /* + vertical offset would go here */, buildingARLocationPositionColumn.z)
        
        // Store the building's name
        let buildingName: String = buildingDict.value(forKey: "name") as! String
        
        // Create building label
        let labelGeometry = SCNText()
        labelGeometry.string = buildingName
        
        // Add SCNNode wrapper
        let labelNode = SCNNode(geometry: labelGeometry)
        labelNode.name = buildingName
        labelNode.position = targetPosition
        
        // Always point the node towards the camera
        labelNode.constraints = [SCNConstraint]()
        labelNode.constraints?.append(SCNBillboardConstraint())
        
        return labelNode
    }
    
    // MARK: - Degrees <--> Radians conversion functions
    
    func degreesToRadians(_ degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(_ radians: Double) -> Double { return radians * 180.0 / .pi }
    
    // ----------------------------------------------
    // MARK: - Position math (lat/long; matrix, etc)
    // ----------------------------------------------
    
    // MARK: Haversine formula
    // Calculates the distance between two lat/long coordinates in miles.
    // Modified from https://gist.github.com/Jamonek/16ecda78cebcd0da5862
    func distanceBetweenPointsInMiles(lat1: Double, long1: Double, lat2: Double, long2: Double) -> Double {
        let radius: Double = 3959.0 // Average radius of the Earth in miles
        let deltaP = degreesToRadians(lat2) - degreesToRadians(lat1)
        let deltaL = degreesToRadians(long2) - degreesToRadians(long1)
        let a = sin(deltaP/2) * sin(deltaP/2) + cos(degreesToRadians(lat1)) * cos(degreesToRadians(lat2)) * sin(deltaL/2) * sin(deltaL/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = radius * c
        return d
    }
    
    // Converts a CLLocation object to a matrix_float4x4 with the 3rd column representing the location in SCNKit coordinates
    func getARCoordinateOfBuilding(userLocation: CLLocation, buildingLocation: CLLocation, distanceFromUserInMiles: Double) -> matrix_float4x4 {
        let bearing = getBearingBetweenPoints(point1: userLocation, point2: buildingLocation)
        let originTransform = matrix_identity_float4x4
        
        // Create a transform with a translation of distance meters away
        let milesPerMeter = 1609.344
        let distanceInMeters = distanceFromUserInMiles * milesPerMeter
        
        // Matrix that will hold the position of the building in AR coordinates
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.z = -1 * Float(distanceInMeters) 
        
        // Rotate the position matrix
        let rotationMatrix = MatrixHelper.rotateMatrixAroundY(degrees: Float(bearing * -1), matrix: translationMatrix)
        
        // Multiply the rotation by the translation
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        
        // Multiply the origin by the translation to get the coordinates
        return simd_mul(originTransform, transformMatrix)
    }
    
    // Adapted from https://stackoverflow.com/questions/26998029/calculating-bearing-between-two-cllocation-points-in-swift
    func getBearingBetweenPoints(point1 : CLLocation, point2 : CLLocation) -> Double {
        
        let lat1 = degreesToRadians(point1.coordinate.latitude)
        let lon1 = degreesToRadians(point1.coordinate.longitude)
        
        let lat2 = degreesToRadians(point2.coordinate.latitude)
        let lon2 = degreesToRadians(point2.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansToDegrees(radiansBearing)
    }
    
    // MARK: - Gesture Handling
    
    @IBAction func userTappedScreen(_ sender: UITapGestureRecognizer) {
        let screenTapPoint: CGPoint = sender.location(in: self.view)
        
        // User tapped the back button
        if backButton.frame.contains(screenTapPoint) && !backButton.isHidden {
            navigationController?.popViewController(animated: true)
            return
        }
        
        // Get the 2D point of the touch in the SceneView
        let sceneViewTapPoint: CGPoint = sender.location(in: self.sceneView)
        
        // Conduct the hit test on the SceneView
        let hitTestResults = sceneView.hitTest(sceneViewTapPoint, options: [.boundingBoxOnly: true])
        
        // If the hit test contains a building label and we know additional information about the building, display it
        if let tappedNode = hitTestResults.first?.node, let _: NSMutableDictionary = dict_LabelNode_BuildingDict[tappedNode.name as Any] as? NSMutableDictionary {
                 displayBuildingInfo(buildingName: tappedNode.name)
        } else if let buildingDetailsNode = hitTestResults.first?.node, buildingDetailsNode.name?.range(of: "detailsNode") != nil {
            // User tapped buildingDetails: display larger building details.
            displayBuildingInfo(buildingName: buildingDetailsNode.name?.replacingOccurrences(of: "-detailsNode", with: ""))
        } else if backButton.isHidden {
            // No nodes were tapped; display the back button
            let animationTime = 1.0
            let animationDelay = 3.0
            
            // Hit test had no results; display back button for a few seconds
            UIView.animate(withDuration: animationTime, delay: 0, animations: {
                    self.backButton.alpha = 1.0
            }, completion:{ (finished: Bool) in
                self.backButton.isHidden = false
            })
            
            // Fade back out
            UIView.animate(withDuration: animationTime, delay: animationDelay, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                self.backButton.alpha = 0
            }, completion: { (finished: Bool) in
                self.backButton.isHidden = true
            })
        }
    }
    
    // MARK: - Building Details
    
    /*
     * Creates a SCNNode that contains a BuildingDetails ViewController and positions it at
     * the anchor's position. Does not add the node to the scene.
     */
    func createPopulatedBuildingDetailsSCNNode(buildingDict: NSMutableDictionary, anchor: SCNVector3) -> SCNNode {
        let buildingDetailViewController = createBuildingDetailsViewControllerFromDict(buildingDict: buildingDict)
        buildingDetailViewController.closeButton.alpha = 0 // Hide the close button
        
        // Create a SCNPlane and add the BuildingDetailsView
        let plane: SCNPlane = SCNPlane()
        
        // Match the ViewController.view's corner radius to prevent rendering white corners
        plane.cornerRadius = (buildingDetailViewController.view?.layer.cornerRadius)! / 4
        
        // Configure the plane
        plane.width = 50
        plane.height = 85
        plane.insertMaterial(SCNMaterial(), at: 0)
        plane.materials[0].diffuse.contents = buildingDetailViewController.view
        
        // Create a node with the plane's geometry and position it in the center of the building's name label
        let planeNode: SCNNode = SCNNode(geometry: plane)
        planeNode.position = anchor
        
        // Always point the node towards the camera
        planeNode.constraints = [SCNConstraint]()
        planeNode.constraints?.append(SCNBillboardConstraint())
        
        return planeNode
    }
    

    // Displays the building's info in an overlay
    func displayBuildingInfo(buildingName: String?) {
        if buildingName != nil {
            let buildingDict: NSMutableDictionary? = dict_LabelNode_BuildingDict[buildingName!] as? NSMutableDictionary
            let buildingDetailViewController = createBuildingDetailsViewControllerFromDict(buildingDict: buildingDict)
            
            // Only allow for one buildingDetails view to be shown at a time.
            if (self.childViewControllers.count <= 0) {
                self.addChildViewController(buildingDetailViewController)

                // Create the scene
                let buildingOverlayScene = SKScene(size: sceneView.bounds.size)
                sceneView.overlaySKScene = buildingOverlayScene

                let viewFromNib: UIView = buildingDetailViewController.view
                viewFromNib.alpha = 0
                
                // Add the view and fade in
                buildingOverlayScene.view!.addSubview(viewFromNib)
                UIView.animate(withDuration: 1.5, animations: { viewFromNib.alpha = self.buildingDetailsOverlayOpacity })
            }
        }
    }
    
    // Create a BuildingDetailsController and populate it asynchronously with data from the API
    func createBuildingDetailsViewControllerFromDict(buildingDict: NSMutableDictionary?) -> BuildingDetailsViewController {
        // Create a new ViewController and pass it the selected building's data
        let buildingDetailViewController = BuildingDetailsViewController.init(nibName: "BuildingDetails", bundle: nil)
        buildingDetailViewController.delegate = self
        
        // NOTE: ViewController.view must be referenced at least once before referencing ANY IBOutlets in the ViewController. Referencing the `view` property implicity calls loadView(), which should never be called directly by the programmer.
        let _: UIView! = buildingDetailViewController.view
        
        // Display the building name
        buildingDetailViewController.buildingNameLabel.text = buildingDict?.value(forKey: "name") as? String
        
        // Get the building's image asynchronously and display it once available
        if let imageAddress = buildingDict?.value(forKey: "imageUrl") as? String,
            let buildingImageUrl = URL(string: imageAddress) {
                downloadAndDisplayImageAsync(url: buildingImageUrl, imageView: buildingDetailViewController.buildingImageview)
        }
        
        // Get the building's description asynchronously and display it once available
        if let descriptionAddress = buildingDict?.value(forKey: "descriptionUrl") as? String,
            let buildingDescriptionUrl = URL(string: descriptionAddress) {
                downloadAndDisplayLabelTextAsync(url: buildingDescriptionUrl, label: buildingDetailViewController.buildingDescriptionLabel)
        }

        return buildingDetailViewController
    }
    
    // Create loading indicator and add it to the passed in view
    func createAndShowLoadingIndicator(addToView: UIView) -> UIActivityIndicatorView {
        let loadingIndicator = UIActivityIndicatorView()
        
        // Add the loading indicator at the center of the view and begin the loading animation
        loadingIndicator.center = CGPoint(x: addToView.frame.size.width  / 2,
                                          y: addToView.frame.size.height / 2);
        addToView.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
        
        return loadingIndicator
    }
    
    // MARK: - Asynchronous data downloading
    
    // Downloads data on a background thread and executes the passed-in closure on completion
    func getDataFromUrlAsync(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    // Download a String on a background thread and display it in the passed in UILabel once completed
    func downloadAndDisplayLabelTextAsync(url: URL, label: UILabel) {
        var text: String?
        
        // Download the text and display it on completion
        getDataFromUrlAsync(url: url) { (data, response, error) in
            if error != nil {
                // Download failed
                text = "No data found"
            } else if let data = data {
                text = String(data: data, encoding: .utf8)
            }
            
            // Display the label
            DispatchQueue.main.async {
                label.text = text
            }
        }
    }
    
    // Download an image on a background thread and display it in the passed in UIImageView once completed
    func downloadAndDisplayImageAsync(url: URL, imageView: UIImageView) {
        var image: UIImage?
        let loadingIndicator = createAndShowLoadingIndicator(addToView: imageView)
        
        // Download the image and display it on completion
        getDataFromUrlAsync(url: url) { (data, response, error) in
            if error != nil {
                // Download failed
                image = UIImage(named: "no-image")
            } else if let data = data {
                image = UIImage(data: data)
            }
            
            // Display the image
            DispatchQueue.main.async {
                loadingIndicator.stopAnimating()
                loadingIndicator.removeFromSuperview()
                imageView.image = image
            }
        }
    }
    
    // MARK: - BuildingDetailsDelegate
    
    // Closes the Building Details subview. 
    func closeBuildingDetailsView(viewController: UIViewController) {
        
        // Fade out the view
        UIView.animate(withDuration: 1.5,
                       animations: { viewController.view.alpha = 0},
                       completion: {(finished:Bool) in
                        // Remove the view after the animation has completed
                        viewController.view.removeFromSuperview()
                        viewController.removeFromParentViewController()
        })
    }
    
    // MARK: - Node animations
    
    // Cross fade between two nodes for the given duration
    func crossFadeNodes(fadeInNode: SCNNode, fadeOutNode: SCNNode, duration: Double) {
        fadeOutNode.runAction(SCNAction.fadeOpacity(to: 0, duration: duration))
        fadeInNode.runAction(SCNAction.fadeOpacity(to: buildingDetailsOverlayOpacity, duration: duration))
    }
    
    func fadeNodeInAndOut(node: SKNode, initialDelay: Double, fadeInDuration: Double, displayDuration: Double, fadeOutDuration: Double) {
        // Fade in the label
        node.run(SKAction.sequence([
            .wait(forDuration: initialDelay),
            .fadeIn(withDuration: fadeInDuration)]))
        
        // Wait and fade out the label
        node.run(SKAction.sequence([
            .wait(forDuration: displayDuration),
            .fadeOut(withDuration: fadeOutDuration),
            .removeFromParent()]))
    }
    
    // MARK: - Show Alert message
    func showAlertMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message:message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        // Create a UIAlertAction object and add it to the alert controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Present the alert controller by calling the presentViewController method
        present(alertController, animated: true, completion: nil)
    }
}
