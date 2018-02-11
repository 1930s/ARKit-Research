//
//  VTPlaceOnMapViewController.swift
//  VTQuest
//
//  Created by Osman Balci on 10/18/17.
//  Copyright © 2017 Osman Balci. All rights reserved.
//

import UIKit
import MapKit

class VTPlaceOnMapViewController: UIViewController, MKMapViewDelegate {
    
    // Instance variable holding the object reference of the MKMapView object created in the Storyboard
    @IBOutlet var mapView: MKMapView!
    
    // Set by upstream view controller VTPlaceInfoViewController
    var selectedBuildingNamePassed = ""
    var mapTypePassed: MKMapType?
    
    // Obtain the object reference to the App Delegate object
    let applicationDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // The amount of north-to-south distance (measured in meters) to use for the span.
    let latitudinalSpanInMeters: Double = 804.672    // = 0.5 mile
    
    // The amount of east-to-west distance (measured in meters) to use for the span.
    let longitudinalSpanInMeters: Double = 804.672   // = 0.5 mile
    
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
        
        titleLabel.text = selectedBuildingNamePassed
        
        titleLabel.font = titleLabel.font.withSize(12)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        self.navigationItem.titleView = titleLabel

        //-----------------------------
        // Dress up the map view object
        //-----------------------------
        
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = false
        mapView.mapType = mapTypePassed!
        
        // Obtain the object reference of the building dictionary for the selected place name
        let dict_vtPlaceAttribute_vtPlaceValue: AnyObject? = applicationDelegate.dict_vtBuildingName_vtBuildingDict[selectedBuildingNamePassed]
        
        /*
         dict_vtPlaceAttribute_vtPlaceValue
         "abbreviation":      Abbreviated Building Name     String
         "category":          Building Category Name        String
         "descriptionUrl":    Building Description URL      String
         "imageUrl":          Building Image URL            String
         "latitude":          Building Latitude             NSNumber
         "longitude":         Building Longitude            NSNumber
         */
        
        let buildingLatitude: Double = (dict_vtPlaceAttribute_vtPlaceValue!["latitude"] as! Double?)!
        let buildingLongitude: Double = (dict_vtPlaceAttribute_vtPlaceValue!["longitude"] as! Double?)!
        
        // Virginia Tech Campus Center Geolocation
        let buildingLocation = CLLocationCoordinate2D(latitude: buildingLatitude, longitude: buildingLongitude)
        
        // Define map's visible region
        let buildingMapRegion: MKCoordinateRegion? = MKCoordinateRegionMakeWithDistance(buildingLocation, latitudinalSpanInMeters, longitudinalSpanInMeters)
        
        // Set the mapView to show the defined visible region
        mapView.setRegion(buildingMapRegion!, animated: true)
        
        //************************************
        // Prepare and Set Building Annotation
        //************************************
        
        // Instantiate an object from the MKPointAnnotation() class and place its obj ref into local variable annotation
        let annotation = MKPointAnnotation()
        
        // Dress up the newly created MKPointAnnotation() object
        annotation.coordinate = buildingLocation
        annotation.title = selectedBuildingNamePassed
        annotation.subtitle = dict_vtPlaceAttribute_vtPlaceValue!["category"] as! String?
        
        // Add the created and dressed up MKPointAnnotation() object to the map view
        mapView.addAnnotation(annotation)
        
    }

    /*
     ------------------------------------------
     MARK: - MKMapViewDelegate Protocol Methods
     ------------------------------------------
     */
    
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
