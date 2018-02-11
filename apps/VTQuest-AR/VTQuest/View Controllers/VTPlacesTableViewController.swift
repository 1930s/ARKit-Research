//
//  VTPlacesTableViewController.swift
//  VTQuest
//
//  Created by Osman Balci on 10/18/17.
//  Copyright © 2017 Osman Balci. All rights reserved.
//

import UIKit

class VTPlacesTableViewController: UITableViewController {

    // Obtain the object reference to the App Delegate object
    let applicationDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    /*
     Create and initialize an empty dictionary to contain the following KEY : VALUE pairings:
     KEY = letter : VALUE = an array of VT place (building) names starting with that letter
     */
    var dict_Letter_ArrayOfPlaceNames  = [String: AnyObject]()
    
    // Create and initialize an empty array to contain the starting letters of VT place (building) names
    var firstLettersOfVTPlaceNames = [String]()
    
    var selectedBuildingNameToPass = ""
    
    /*
     -----------------------
     MARK: - View Life Cycle
     -----------------------
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         -----------------------------------------------------------------------------------------------------
         Objective: We want to identify the first letters with which the VT place (building) names start.
         We will list the letters as an index in the table view so that the user
         can select a letter to jump to the names starting with that letter.
         
         Create a changeable Dictionary with the following key-value pairs:
         KEY   = Alphabet letter from A to Z
         VALUE = Obj ref of an Array containing the VT place (building) names that start with the letter = KEY
         -----------------------------------------------------------------------------------------------------
         */
        
        // Obtain the name of the first VT place (building) from the global data accessible from AppDelegate
        let firstVTPlaceName = applicationDelegate.vtBuildingNames[0]
        
        // Create an array with its first value being firstVTPlaceName
        var placeNamesForLetter = [String]()
        placeNamesForLetter.append(firstVTPlaceName)
        
        // Instantiate a character string object containing the letter A
        // and store its object reference into the local variable previousLetter
        var previousFirstLetter: Character = "A"
        
        // Store the number of VT place (building) names into local variable noOfPlaces
        let noOfPlaces = applicationDelegate.vtBuildingNames.count
        
        // Since we already stored the first VT place name at index 0, we start index j with 1
        for j in 1..<noOfPlaces {
            
            // Obtain the jth VT place name
            let placeName = applicationDelegate.vtBuildingNames[j]
            
            // Obtain the first character of the VT place name.
            let currentFirstLetter: Character = placeName[placeName.startIndex]
            
            if currentFirstLetter == previousFirstLetter {
                
                placeNamesForLetter.append(placeName)
                
            } else {
                // Add array of VT place names starting with previousFirstLetter to the dictionary
                dict_Letter_ArrayOfPlaceNames[String(previousFirstLetter)] = placeNamesForLetter as AnyObject?
                
                previousFirstLetter = currentFirstLetter
                
                // Empty the placeNamesForLetter array
                placeNamesForLetter.removeAll(keepingCapacity: false)
                
                // Set the value at index 0 to placeName
                placeNamesForLetter.append(placeName)
            }
        }
        
        // Add array of VT place (building) names starting with previousFirstLetter to the dictionary
        dict_Letter_ArrayOfPlaceNames[String(previousFirstLetter)] = placeNamesForLetter as AnyObject?
        
        // Obtain the index letters to diplay for the user to select one to jump to its section
        firstLettersOfVTPlaceNames  = Array(dict_Letter_ArrayOfPlaceNames.keys)
        
        // Sort the index letters within itself in alphabetical order
        firstLettersOfVTPlaceNames.sort { $0 < $1 }
    }
    
    /*
     ------------------------------------------------
     MARK: - UITableView Data Source Protocol Methods
     ------------------------------------------------
     */
    
    // We are implementing a Grouped table view style at runtime
    
    //---------------------------------------
    // Return Number of Sections in Table View
    //---------------------------------------
    
    // Asks the data source to return the number of sections in the table view
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        // number of table sections = number of letters
        return firstLettersOfVTPlaceNames.count
    }
    
    //--------------------------------
    // Return Number of Rows in Section
    //--------------------------------
    
    // Number of rows in a given section (index letter) = Number of VT place names starting with that letter
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Obtain the index letter for the given section number
        let indexLetter = firstLettersOfVTPlaceNames[section]
        
        // Obtain the object reference to the array containing the place names starting with that index letter
        let arrayOfPlaceNames: AnyObject? = dict_Letter_ArrayOfPlaceNames[indexLetter]
        
        // Unwrap and typecast the object pointed to by arrayOfPlaceNames as an array of String values
        let listOfPlaceNames = arrayOfPlaceNames! as! [String]
        
        // Number of place names starting with the index letter = Number of rows in that index letter section
        return listOfPlaceNames.count
    }
    
    //----------------------------
    // Set Title for Section Header
    //----------------------------
    
    // Asks the data source to return the section title for a given section number
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        
        return firstLettersOfVTPlaceNames[section]
    }
    
    //-------------------------------------
    // Prepare and Return a Table View Cell
    //-------------------------------------
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "VTPlaces", for: indexPath) as UITableViewCell
        
        let sectionNumber = (indexPath as NSIndexPath).section
        let rowNumber = (indexPath as NSIndexPath).row
        
        // Obtain the index letter for the given section number
        let indexLetter = firstLettersOfVTPlaceNames[sectionNumber]
        
        // Obtain the object reference to the array containing the place names starting with that index letter
        let arrayOfPlaceNames: AnyObject? = dict_Letter_ArrayOfPlaceNames[indexLetter]
        
        // Unwrap and typecast the object pointed to by arrayOfPlaceNames as an array of String values
        var listOfPlaceNames = arrayOfPlaceNames! as! [String]
        
        // Obtain the place name at the row number
        let selectedPlaceName = listOfPlaceNames[rowNumber]
        
        // Set the cell title to be the selected place name
        cell.textLabel!.text = selectedPlaceName
        
        // Set the cell image to VT logo
        cell.imageView!.image = UIImage(named: "vtLogo.png")
        
        // Obtain the object reference of the building dictionary for the selected place name
        let dict_vtPlaceAttribute_vtPlaceValue: AnyObject? = applicationDelegate.dict_vtBuildingName_vtBuildingDict[selectedPlaceName]
        
        // Obtain the value for the category for the selected place name
        let vtPlaceCategory = dict_vtPlaceAttribute_vtPlaceValue!["category"] as! String
        
        // Set table view cell (row) subtitle to VT place category
        // Select Subtitle from the table view cell Style menu in Storyboard for this to work
        cell.detailTextLabel?.text = vtPlaceCategory
        
        return cell
    }
    
    //----------------------------
    // Return Section Index Titles
    //----------------------------
    
    /*
     Asks the data source to return all of the section titles, i.e., letters from A to Z to display them as an
     index on the right side of the table view so that the user can tap on a letter to jump to its section.
     */
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return firstLettersOfVTPlaceNames
    }
    
    /*
     --------------------------------------------
     MARK: - UITableView Delegate Protocol Method
     --------------------------------------------
     */
    
    //---------------------------------------------
    // Selection of a VT Place (Building) Name (Row)
    //---------------------------------------------
    
    // Tapping a row, VT Place (Building) Name, displays information about that place (building)
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let sectionNumber = (indexPath as NSIndexPath).section
        let rowNumber = (indexPath as NSIndexPath).row
        
        // Obtain the index letter for the given section number
        let indexLetter = firstLettersOfVTPlaceNames[sectionNumber]
        
        // Obtain the object reference to the array containing the place names starting with the index letter
        let arrayOfPlaceNames: AnyObject? = dict_Letter_ArrayOfPlaceNames[indexLetter]
        
        // Unwrap and typecast the object pointed to by arrayOfPlaceNames as an array of String values
        var listOfPlaceNames = arrayOfPlaceNames! as! [String]
        
        // Obtain the name of the building selected at the row number
        selectedBuildingNameToPass = listOfPlaceNames[rowNumber]
        
        // Perform the segue named vtPlaceInfo
        performSegue(withIdentifier: "vtPlaceInfo", sender: self)
    }
    
    /*
     -------------------------
     MARK: - Prepare for Segue
     -------------------------
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "vtPlaceInfo" {
            
            // Obtain the object reference of the destination (downstream) view controller
            let vtPlaceInfoViewController: VTPlaceInfoViewController = segue.destination as! VTPlaceInfoViewController
            
            // Pass the following data to downstream view controller VTPlaceInfoViewController
            vtPlaceInfoViewController.selectedBuildingNamePassed = selectedBuildingNameToPass
        }
    }
    
}
