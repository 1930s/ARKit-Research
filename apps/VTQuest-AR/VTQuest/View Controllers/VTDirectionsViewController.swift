//
//  VTDirectionsViewController.swift
//  VTQuest
//
//  Created by Osman Balci on 10/19/17.
//  Copyright © 2017 Osman Balci. All rights reserved.
//

import UIKit

class VTDirectionsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // Instance variables holding the object references of the UI objects created in the Storyboard
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var setFromLabel: UILabel!
    @IBOutlet var setToLabel: UILabel!
    @IBOutlet var directionsTypeSegmentedControl: UISegmentedControl!
    
    // Obtain the object reference to the App Delegate object
    let applicationDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate

    // Data to pass to downstream view controller VTDirectionsMapViewController
    var fromPlaceSelected = ""
    var toPlaceSelected = ""
    var directionsType = ""
    
    var viewShownFirstTime = true
    
    /*
     -----------------------
     MARK: - View Life Cycle
     -----------------------
     */
    override func viewDidLoad() {
        super.viewDidLoad() 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Obtain the number of the row in the middle of the VT place names list
        let numberOfVTPlaces = applicationDelegate.vtBuildingNames.count
        let numberOfRowToShow = Int(numberOfVTPlaces / 2)
        
        // Show the picker view of VT place names from the middle
        pickerView.selectRow(numberOfRowToShow, inComponent: 0, animated: false)
        
        // Deselect the earlier selected directions type
        directionsTypeSegmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
        
        if viewShownFirstTime {
            viewShownFirstTime = false
            // Do not clear "Selected VT place FROM" and "Selected VT place TO"
        } else {
            // Clear the earlier selections
            setFromLabel.text = ""
            setToLabel.text = ""
        }
    }
    
    /*
     ------------------------
     MARK: - IBAction Methods
     ------------------------
     */
    
    @IBAction func setFromButtonTapped(_ sender: UIButton) {
        
        let selectedRowNumber = pickerView.selectedRow(inComponent: 0)
        fromPlaceSelected = applicationDelegate.vtBuildingNames[selectedRowNumber]
        setFromLabel.text = fromPlaceSelected
    }
    
    @IBAction func setToButtonTapped(_ sender: UIButton) {
        
        let selectedRowNumber = pickerView.selectedRow(inComponent: 0)
        toPlaceSelected = applicationDelegate.vtBuildingNames[selectedRowNumber]
        setToLabel.text = toPlaceSelected
    }
    
    @IBAction func clearButtonTapped(_ sender: UIButton) {
        
        setFromLabel.text = ""
        setToLabel.text = ""
    }
    
    @IBAction func getDirectionsOnCampus(_ sender: UISegmentedControl) {
        
        // If the starting and/or destination VT place name is not selected, alert the user
        
        if setFromLabel.text == "" || setToLabel.text == "" ||
            setFromLabel.text == "Selected VT place FROM" ||
            setToLabel.text == "Selected VT place TO" {
            
            // Deselect the earlier selected directions type
            directionsTypeSegmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
            
            /*
             Create a UIAlertController object; dress it up with title, message, and preferred style;
             and store its object reference into local constant alertController
             */
            let alertController = UIAlertController(title: "Selection Missing!",
                                                    message: "Please select both From and To places for directions!",
                                                    preferredStyle: UIAlertControllerStyle.alert)
            
            // Create a UIAlertAction object and add it to the alert controller
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Present the alert controller by calling the presentViewController method
            present(alertController, animated: true, completion: nil)
            
            return
        }
        
        switch sender.selectedSegmentIndex {
        case 0:
            directionsType = "Driving"
        case 1:
            directionsType = "Walking"
        default:
            return
        }
        
        // Perform the segue named CampusDirections
        performSegue(withIdentifier: "CampusDirections", sender: self)
    }
    
    /*
     ----------------------------------------
     MARK: - UIPickerView Data Source Methods
     ----------------------------------------
     */
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return applicationDelegate.vtBuildingNames.count
    }
    
    /*
     ------------------------------------
     MARK: - UIPickerView Delegate Method
     ------------------------------------
     */
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return applicationDelegate.vtBuildingNames[row]
    }
    
    /*
     -------------------------
     MARK: - Prepare for Segue
     -------------------------
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "CampusDirections" {
            
            // Obtain the object reference of the destination (downstream) view controller
            let vtDirectionsMapViewController: VTDirectionsMapViewController = segue.destination as! VTDirectionsMapViewController
            
            // Pass the following data to downstream view controller VTDirectionsMapViewController
            vtDirectionsMapViewController.fromPlaceSelectedPassed = fromPlaceSelected
            vtDirectionsMapViewController.toPlaceSelectedPassed = toPlaceSelected
            vtDirectionsMapViewController.directionsTypePassed = directionsType
        }
    }
    
}
