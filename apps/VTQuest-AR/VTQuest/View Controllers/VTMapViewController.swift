//
//  VTMapViewController.swift
//  VTQuest
//
//  Created by Osman Balci on 10/18/17.
//  Copyright © 2017 Osman Balci. All rights reserved.
//

import UIKit
import MapKit

class VTMapViewController: UIViewController, MKMapViewDelegate {

    // Instance variable holding the object reference of the MKMapView object created in the Storyboard
    @IBOutlet var mapView: MKMapView!
    
    // Virginia Tech Campus Center Geolocation
    let vtCampusCenterLocation = CLLocationCoordinate2D(latitude: 37.227778, longitude: -80.422014)
    
    // The amount of north-to-south distance (measured in meters) to use for the span.
    let latitudinalSpanInMeters: Double = 1609.344    // = 1 mile
    
    // The amount of east-to-west distance (measured in meters) to use for the span.
    let longitudinalSpanInMeters: Double = 1609.344   // = 1 mile
    
    /*
     -----------------------
     MARK: - View Life Cycle
     -----------------------
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //-----------------------------
        // Dress up the map view object
        //-----------------------------
        
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = false
        
        showMap()
    }
    
    /*
     --------------------
     MARK: - Set Map Type
     --------------------
     */
    // This method is invoked when the user selects a map type to display
    @IBAction func setMapType(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = MKMapType.standard
        case 1:
            mapView.mapType = MKMapType.satellite
        case 2:
            mapView.mapType = MKMapType.hybrid
        default:
            return
        }
        
        showMap()
    }
    
    /*
     ----------------
     MARK: - Show Map
     ----------------
     */
    func showMap() {

        // Define map's visible region
        let vtMapRegion: MKCoordinateRegion? = MKCoordinateRegionMakeWithDistance(vtCampusCenterLocation, latitudinalSpanInMeters, longitudinalSpanInMeters)
        
        // Set the mapView to show the defined visible region
        mapView.setRegion(vtMapRegion!, animated: true)
        
        //*************************************
        // Prepare and Set VT Campus Annotation
        //*************************************
        
        // Instantiate an object from the MKPointAnnotation() class and place its obj ref into local variable annotation
        let annotation = MKPointAnnotation()
        
        // Dress up the newly created MKPointAnnotation() object
        annotation.coordinate = vtCampusCenterLocation
        annotation.title = "Virginia Tech Campus"
        annotation.subtitle = "Go Hokies!"
        
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
