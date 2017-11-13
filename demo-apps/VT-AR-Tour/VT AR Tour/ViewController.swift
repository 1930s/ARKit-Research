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
    
    let vtBuildingsWSBaseUrl: String = "http://orca.cs.vt.edu/VTBuildingsJAX-RS/webresources/vtBuildings"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
       
        // User must enable location services to use this app
        if !CLLocationManager.locationServicesEnabled() {
            showAlertMessage(title: "Location Services Disabled", message: "You must enable location services to use this app")
            
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
        getLocation()
    }
    
    func setupScene() {
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        //sceneView.scene = scene
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
        
        // Report ALL device movement
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Get the highest possible degree of accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

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
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    /*
     ------------------------------------------
     MARK: - CLLocationManager Delegate Methods
     ------------------------------------------
     */
    // New location data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
        if let currentLocation: CLLocation = locations.last {
            var jsonData: Data?
            
            // Download JSON data in a single thread
            // TODO: cache the data and use that instead
            do {
                jsonData = try Data(contentsOf: URL(string: vtBuildingsWSBaseUrl)!, options: NSData.ReadingOptions.dataReadingMapped)
            } catch let error as NSError {
                showAlertMessage(title: "HTTP error", message: "Error getting VT Building data from the server: \(error.localizedDescription)")
            }
        
            if let jsonDataFromApi = jsonData {
                // Getting the JSON was successful
                do {
                    let jsonArray = try JSONSerialization.jsonObject(with: jsonDataFromApi, options: .mutableContainers) as! NSArray
                    
                    // Loop through each building in the response
                    for building in jsonArray {
                        let buildingDict = building as! NSMutableDictionary
                        
                        let buildingLocation: CLLocation = CLLocation(latitude: buildingDict["latitude"]! as! CLLocationDegrees, longitude: buildingDict["longitude"]! as! CLLocationDegrees)
                        
                        // Compute the distance between the user's current location and the building's location
                        let distanceFromUserInMiles: Double = distanceBetweenPointsInMiles(lat1: currentLocation.coordinate.latitude, long1: currentLocation.coordinate.longitude, lat2: buildingLocation.coordinate.latitude, long2: buildingLocation.coordinate.longitude)
                        buildingDict["distanceFromUser"] = distanceFromUserInMiles
                        
                        // Add a marker in the building's position
                        let buildingARLocation: matrix_float4x4 = getARCoordinateOfBuilding(userLocation: currentLocation, buildingLocation: buildingLocation, distanceFromUserInMiles: distanceFromUserInMiles)
                        let buildARLocationPositionColumn = buildingARLocation.columns.3
                        let targetPosition: SCNVector3 = SCNVector3Make(buildARLocationPositionColumn.x, buildARLocationPositionColumn.y /* + vertical offset would go here */, buildARLocationPositionColumn.z)
//                        let cubeGeometry: SCNBox = SCNBox(
//                            width: 10, height: 10, length: 10, chamferRadius: 0)
                        let labelNode = SKLabelNode()
                        labelNode.text = buildingDict["name"]
                        labelNode.position = targetPosition
                        // Add the node to the scene
                        sceneView.scene.rootNode.addChildNode(labelNode)

                        
                    }

                    // Sort the array of buildings
//                    var sortedBuildingArray = jsonArray.sorted{($1 as! NSDictionary)["distanceFromUser"] as! Double > ($0 as! NSDictionary)["distanceFromUser"] as! Double}
                    
//                    let first = sortedBuildingArray.first! as! NSDictionary
//                    let firstLocation: CLLocation = CLLocation(latitude: first["latitude"]! as! CLLocationDegrees, longitude: first["longitude"]! as! CLLocationDegrees)
//                    showAlertMessage(title: "", message: "The closest building to you is \(first["name"]!). It is \(first["distanceFromUser"]!) miles away.")
                } catch let error as NSError {
                    showAlertMessage(title: "Error in JSON serialization", message: error.localizedDescription)
                }
            }
        }
    }
    
    // New heading information available
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //
        return
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
