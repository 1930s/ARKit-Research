//
//  VTPlaceInfoViewController.swift
//  VTQuest
//
//  Created by Osman Balci on 10/18/17.
//  Copyright © 2017 Osman Balci. All rights reserved.
//

import UIKit
import MapKit

class VTPlaceInfoViewController: UIViewController {

    // Instance variables holding the object references of the UI objects created in the Storyboard
    @IBOutlet var buildingNameLabel:            UILabel!
    @IBOutlet var buildingImageView:            UIImageView!
    @IBOutlet var buildingAbbreviatedNameLabel: UILabel!
    @IBOutlet var buildingCategoryNameLabel:    UILabel!
    @IBOutlet var buildingDescriptionTextView:  UITextView!
    @IBOutlet var mapTypeSegmentedControl:      UISegmentedControl!
    
    // Set by upstream view controller VTPlacesTableViewController
    var selectedBuildingNamePassed = ""
    
    // Obtain the object reference to the App Delegate object
    let applicationDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Map type to be passed to downstream view controller VTPlaceOnMapViewController
    var mapTypeToPass: MKMapType?
    
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
        
        // Obtain the object reference of the dictionary of the selected building
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
        
        buildingAbbreviatedNameLabel.text = dict_vtPlaceAttribute_vtPlaceValue!["abbreviation"] as! String?
        
        buildingCategoryNameLabel.text = dict_vtPlaceAttribute_vtPlaceValue!["category"] as! String?
        
        let url = dict_vtPlaceAttribute_vtPlaceValue!["descriptionUrl"] as! String
        
        if let buildingDescriptionUrl = URL(string: url) {
            do {
                self.buildingDescriptionTextView.text = try String(contentsOf: buildingDescriptionUrl)
            } catch {
                showErrorMessage("Building \(selectedBuildingNamePassed) description URL does not return the description text!")
                return
            }
        } else {
            showErrorMessage("Building \(selectedBuildingNamePassed) description URL is invalid!")
            return
        }
        
        buildingNameLabel.text = selectedBuildingNamePassed
        
        let imageURL = dict_vtPlaceAttribute_vtPlaceValue!["imageUrl"] as! String?
        let bldgImgUrl = URL(string: imageURL!)
        var errorInReadingImageData: NSError?
        var imageData: Data?
        
        do {
            imageData = try Data(contentsOf: bldgImgUrl!, options: NSData.ReadingOptions.mappedIfSafe)
        } catch let error as NSError {
            errorInReadingImageData = error
            imageData = nil
        }
        
        if let vtBuildingImage = imageData {
            buildingImageView.image = UIImage(data: vtBuildingImage)
        } else {
            if errorInReadingImageData != nil {
                // Take no action since a VT building may not have an image.
            }
            // When there is no photo available for the building, display the image named imageUnavailable.png
            buildingImageView.image = UIImage(named: "imageUnavailable.png")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Set the segmented control to show no selection before the view appears
        self.mapTypeSegmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Scroll the UITextView all the way to the top to show the building description from the top
        self.buildingDescriptionTextView.scrollRangeToVisible(NSMakeRange(0, 0))
    }
    
    /*
     --------------------------
     MARK: - Show Error Message
     --------------------------
     */
    func showErrorMessage(_ message: String) {
        
        /*
         Create a UIAlertController object; dress it up with title, message, and preferred style;
         and store its object reference into local constant alertController
         */
        let alertController = UIAlertController(title: "Unable to Obtain Data!", message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        // Create a UIAlertAction object and add it to the alert controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
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
            mapTypeToPass = MKMapType.standard
        case 1:
            mapTypeToPass = MKMapType.satellite
        case 2:
            mapTypeToPass = MKMapType.hybrid
        default:
            return
        }
        
        // Perform the segue named vtPlaceOnMap
        performSegue(withIdentifier: "vtPlaceOnMap", sender: self)
    }
    
    /*
     -------------------------
     MARK: - Prepare for Segue
     -------------------------
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "vtPlaceOnMap" {
            
            // Obtain the object reference of the destination (downstream) view controller
            let vtPlaceOnMapViewController: VTPlaceOnMapViewController = segue.destination as! VTPlaceOnMapViewController
            
            // Pass the following data to downstream view controller VTPlaceOnMapViewController
            vtPlaceOnMapViewController.mapTypePassed = mapTypeToPass
            vtPlaceOnMapViewController.selectedBuildingNamePassed = selectedBuildingNamePassed
        }
    }
    
}
