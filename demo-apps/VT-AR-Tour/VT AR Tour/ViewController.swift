//
//  ViewController.swift
//  VT AR Tour
//
//  Created by Patrick Gatewood on 10/31/17.
//  Copyright © 2017 Patrick Gatewood. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    // A strong reference to CLLocationManager is required by the CoreLocation API.
    var locationManager = CLLocationManager()
    
    // JSON read from the Document directory
    var jsonInDocumentDirectory: Data? = nil
    
    var buildingLocationNodes: [SCNNode]? = nil
    
    let vtBuildingsWSBaseUrl: String = "http://orca.cs.vt.edu/VTBuildingsJAX-RS/webresources/vtBuildings"
    
    // MARK - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
       
        // User must enable location services to use this app
        if !CLLocationManager.locationServicesEnabled() {
            showAlertMessage(title: "Location Services Disabled", message: "You must enable location services to use this app")
            
            return
        }
        
        // Set up tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.userTappedScreen(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Get the user's location
        locationManager.requestWhenInUseAuthorization()
        getLocation()
        
        // Display a hint for a few seconds
        sceneView.overlaySKScene = createOverlayHintLabel(withText: "Tap a building or walk closer to display more information.")
        fadeNodeInAndOut(node: sceneView.overlaySKScene!, initialDelay: 2.0, fadeInDuration: 1.0, displayDuration: 6.0, fadeOutDuration: 1.0)
    }
    
    // Creates an overlay containing a label with hint text and a transucent background
    func createOverlayHintLabel(withText: String) -> SKScene {
        // Create an overlay banner to be positioned in the middle of the SceneView.
        let overlayScene = SKScene(size: sceneView.bounds.size)
        overlayScene.scaleMode = .resizeFill
        
        // Configure the hint label
        let hintLabel = SKLabelNode(text: withText)
        hintLabel.fontSize = 40
        hintLabel.verticalAlignmentMode = .center
        hintLabel.preferredMaxLayoutWidth = overlayScene.size.width
        hintLabel.numberOfLines = 2 // Don't limit the number of lines
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
    
    func getLocation() {
        // The user has not authorized location monitoring
        if (CLLocationManager.authorizationStatus() == .denied) {
            showAlertMessage(title: "App Not Authorized", message: "Unable to determine your location: please allow VT AR Tour to use your location.")
            
            // Try to get location authorization again
            locationManager.requestWhenInUseAuthorization()
            
            return
        }
        
        locationManager.delegate = self
        
        // TODO for debugging. Can choose a less accurate filter later.
        // Report ALL device movement
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Get the highest possible degree of accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        
        // Defines the ARSession's coordinate system based on gravity and the compass heading in the device. Note: THIS IS CRITICALLY IMPORTANT for location-based AR.
        configuration.worldAlignment = .gravityAndHeading

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
 
    // MARK: - Gesture Handling Action methods
    
    @IBAction func userTappedScreen(_ sender: UITapGestureRecognizer) {
        print("user tapped screen")
        // Get the 2D point of the touch in the SceneView
        let tapPoint: CGPoint = sender.location(in: self.sceneView)
        
        // Conduct the hit test on the SceneView
        let hitTestResults: [ARHitTestResult] = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        
        if hitTestResults.isEmpty {
            return
        }
        
        // Pick the closest building
        let result: ARHitTestResult = hitTestResults[0]
        
        print("hit test result: \(result)")
    }
  
    // MARK: - CLLocationManager Delegate Methods

    // New location data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Need to wait until at least one heading update comes through. If we proceed before this, our coordinate system won't be set up correctly
        if manager.heading?.magneticHeading == nil {
            return
        }
        
        if let currentLocation: CLLocation = locations.last {
            //print("Current location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude) location size: \(locations.count)")
            // Fetch the VT Buildings JSON if necessary
            if jsonInDocumentDirectory == nil {
                jsonInDocumentDirectory = getVTBuildingsJSON()
            }
            
            if let jsonDataFromApi = jsonInDocumentDirectory {
                // Getting the JSON was successful
                do {
                    let jsonArray = try JSONSerialization.jsonObject(with: jsonDataFromApi, options: .mutableContainers) as! NSArray
                    
                    if buildingLocationNodes == nil {
                        buildingLocationNodes = [SCNNode]()
                    }
                    
                    // TODO remove: example building
                    // -----------------------------------------------------------------
                    let testBuilding = jsonArray.firstObject as! NSMutableDictionary
                    // coordinates of The Edge Apartments
                    testBuilding["latitude"] = 37.235593
                    testBuilding["longitude"] = -80.423771
                    testBuilding["name"] = "The Edge Apartments"
                    // -----------------------------------------------------------------
                    
                    let dict_LabelNode_BuildingDict = NSMutableDictionary()
                    
                    // Loop through each building in the response
                    for building in jsonArray {
                        let buildingDict = building as! NSMutableDictionary
                        let buildingLocation: CLLocation = CLLocation(latitude: buildingDict["latitude"]! as! CLLocationDegrees, longitude: buildingDict["longitude"]! as! CLLocationDegrees)
                        
                        // Compute the distance between the user's current location and the building's location
                        let distanceFromUserInMiles: Double = distanceBetweenPointsInMiles(lat1: currentLocation.coordinate.latitude, long1: currentLocation.coordinate.longitude, lat2: buildingLocation.coordinate.latitude, long2: buildingLocation.coordinate.longitude)
                        
                        // TODO determine if this is an appropriate range
                        if (distanceFromUserInMiles >= 0.5) {
                            continue
                        }
//                         print("distance from user in miles: \(distanceFromUserInMiles)")
                        
                        // Record how far the building is from the user.
                        buildingDict["distanceFromUser"] = distanceFromUserInMiles
                        
                        // Create a building label node and record it and its related dictionary in another dictionary
                        let labelNode: SCNNode = createBuildingLabelNode(currentLocation, buildingLocation, distanceFromUserInMiles, buildingDict: buildingDict)
                        dict_LabelNode_BuildingDict[labelNode] = buildingDict
                        
                        // Only add the building label if it doesn't already exist
                        let buildingLabelNode = sceneView.scene.rootNode.childNode(withName: labelNode.name!, recursively: false)
                        if (buildingLabelNode == nil) {
                            // Add the node to the scene
                            sceneView.scene.rootNode.addChildNode(labelNode)
                        }
                    }
                    // TODO Prevent labels from rendering "on top"/"in front" of each other. You can't read it if this happens.
                } catch let error as NSError {
                    showAlertMessage(title: "Error in JSON serialization", message: error.localizedDescription)
                }
            }
        }
    }

    // New heading information available
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //print("User is facing: \(newHeading.magneticHeading)")
        return
    }
    
    // MARK: Get JSON Data
    
    // Gets the VT Buildings JSON from the device's cache or from the
    func getVTBuildingsJSON() -> Data? {
        do {
            // Try to read the JSON from the device's Document directory
            jsonInDocumentDirectory = getJsonInDocumentDirectory(jsonFileName: "VTBuildings.plist")
            
            if jsonInDocumentDirectory != nil {
                // Successfully read cached data
                print("read json from cache")
                return jsonInDocumentDirectory
            } else {
                // Reading cached data failed; download JSON data from the API in a single thread
                print("had to download json data")
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
            print("Error writing to cache file: \(error.localizedDescription)")
        }
    }
    
    // MARK - Create Building Labels
    func createBuildingLabelNode(_ currentLocation: CLLocation, _ buildingLocation: CLLocation, _ distanceFromUserInMiles: Double, buildingDict: NSMutableDictionary) -> SCNNode {
        
        // Add a marker in the building's position
        let buildingARLocation: matrix_float4x4 = getARCoordinateOfBuilding(userLocation: currentLocation, buildingLocation: buildingLocation, distanceFromUserInMiles: distanceFromUserInMiles)
        let buildingARLocationPositionColumn = buildingARLocation.columns.3
        let targetPosition: SCNVector3 = SCNVector3Make(buildingARLocationPositionColumn.x, buildingARLocationPositionColumn.y /* + vertical offset would go here */, buildingARLocationPositionColumn.z)
        
        // Create building label
        let labelGeometry = SCNText()
        labelGeometry.string = buildingDict.value(forKey: "name")
        let labelNode = SCNNode(geometry: labelGeometry)
        let buildingName: String = buildingDict.value(forKey: "name") as! String
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
    
    // MARK: - Haversine formula
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
    
    // MARK - Bearing between two points
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
