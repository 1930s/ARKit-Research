//
//  VTDirectionsMapViewController.swift
//  VTQuest
//
//  Created by Osman Balci on 10/19/17.
//  Copyright © 2017 Osman Balci. All rights reserved.
//

import UIKit
import MapKit

class VTDirectionsMapViewController: UIViewController, MKMapViewDelegate {
    
    // Instance variable holding the object reference of the MKMapView object created in the Storyboard
    @IBOutlet var mapView: MKMapView!
    
    // Obtain the object reference to the App Delegate object
    let applicationDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Set by upstream view controller VTDirectionsViewController
    var fromPlaceSelectedPassed = ""
    var toPlaceSelectedPassed   = ""
    var directionsTypePassed    = ""
    
    /*
     -----------------------
     MARK: - View Life Cycle
     -----------------------
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //--------------------------------------------------
        // Adjust the title to fit within the navigation bar
        //--------------------------------------------------
        
        let navigationBarWidth = self.navigationController?.navigationBar.frame.width
        let navigationBarHeight = self.navigationController?.navigationBar.frame.height
        let labelRect = CGRect(x: 0, y: 0, width: navigationBarWidth!, height: navigationBarHeight!)
        let titleLabel = UILabel(frame: labelRect)
        
        titleLabel.text = "\(directionsTypePassed) from \(fromPlaceSelectedPassed) to \(toPlaceSelectedPassed)"
        
        titleLabel.font = titleLabel.font.withSize(12)
        titleLabel.numberOfLines = 3
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        self.navigationItem.titleView = titleLabel
        
        //----------------------------------------------------------------------------------
        // Obtain the GPS coordinates (latitude,longitude) for the VT place selected as FROM
        //----------------------------------------------------------------------------------
        
        // Obtain the object reference to AnyObject for the VT place name selected as From
        let placeFromDictionary: AnyObject? = applicationDelegate.dict_vtBuildingName_vtBuildingDict[fromPlaceSelectedPassed]
        
        let latitudeFrom: Double = (placeFromDictionary!["latitude"] as! Double?)!
        let longitudeFrom: Double = (placeFromDictionary!["longitude"] as! Double?)!
        
        //----------------------------------------------------------------------------------
        // Obtain the GPS coordinates (latitude,longitude) for the VT place selected as TO
        //----------------------------------------------------------------------------------
        
        // Obtain the object reference to AnyObject for the VT place name selected as To
        let placeToDictionary: AnyObject? = applicationDelegate.dict_vtBuildingName_vtBuildingDict[toPlaceSelectedPassed]
        
        let latitudeTo: Double = (placeToDictionary!["latitude"] as! Double?)!
        let longitudeTo: Double = (placeToDictionary!["longitude"] as! Double?)!
        
        //-----------------------------
        // Prepare to Obtain Directions
        //-----------------------------
        
        // Instantiate an object that specifies the start and end points of a route with mode of transportation
        let directionsRequest = MKDirectionsRequest()
        
        // Dress up the directions request object
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitudeFrom, longitude: longitudeFrom), addressDictionary: nil))
        
        directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitudeTo, longitude: longitudeTo), addressDictionary: nil))
        directionsRequest.requestsAlternateRoutes = false
        
        // Set transportation type
 
        switch directionsTypePassed {
        case "Driving":
            directionsRequest.transportType = .automobile
        case "Walking":
            directionsRequest.transportType = .walking
        default:
            return
        }
        
        //----------------------------
        // Compute and Show Directions
        //----------------------------
        
        // Instantiate an object that computes directions based on directionsRequest
        let directions = MKDirections(request: directionsRequest)
        
        directions.calculate { [unowned self] response, error in guard let unwrappedResponse = response else { return }
            
            for route in unwrappedResponse.routes {
                self.mapView.add(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                self.mapView.mapType = MKMapType.satellite
            }
        }
    }
    
    /*
     ------------------------------------------
     MARK: - MKMapViewDelegate Protocol Methods
     ------------------------------------------
     */
    
    /*
     Asks the delegate for a renderer object to use when drawing the specified overlay. [Apple]
     mapView    --> The map view that requested the renderer object.
     overlay    --> The overlay object that is about to be displayed.
     */
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        /*
         Instantiate a MKPolylineRenderer object for visual polyline representation
         of the directions to be displayed as an overlay on top of the map.
         */
        let polylineRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        
        // Dress up the polyline for visual representation of directions
        polylineRenderer.strokeColor = UIColor.red
        polylineRenderer.lineWidth = 1.0
        
        return polylineRenderer
    }
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        // Starting to load the map. Show the animated activity indicator in the status bar
        // to indicate to the user that the map view object is busy loading the map.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        // Finished loading the map. Hide the activity indicator in the status bar.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        
        // An error occurred during the map load. Hide the activity indicator in the status bar.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        /*
         Create a UIAlertController object; dress it up with title, message, and preferred style;
         and store its object reference into local constant alertController
         */
        let alertController = UIAlertController(title: "Unable to Load the Map!",
                                                message: "Error description: \(error.localizedDescription)",
            preferredStyle: UIAlertControllerStyle.alert)
        
        // Create a UIAlertAction object and add it to the alert controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
    
}

