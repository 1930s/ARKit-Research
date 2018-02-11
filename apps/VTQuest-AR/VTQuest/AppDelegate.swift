//
//  AppDelegate.swift
//  VTQuest
//
//  Created by Osman Balci on 10/18/17.
//  Copyright © 2017 Osman Balci. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /*
     Create and initialize a Dictionary to be accessible globally by all classes in our project.
     KEY     = VT building name
     VALUE   = Object reference of another dictionary containing data about the VT building
     */
    var dict_vtBuildingName_vtBuildingDict = [String: AnyObject]()
    
    // Create and initialize an Array to hold the VT building names to be accessible globally by all classes in our project.
    var vtBuildingNames = [String]()
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        /*
         --------------------------------------------------------------------------------------------------------------------------
         VTBuildingsJAX-RS is a RESTful Web Services API created by Dr. Balci. JAX-RS stands for Java API for RESTful Web Services.
         Students learn how to create VTBuildingsJAX-RS in Dr. Balci's CS3754 Cloud Software Development course.
         --------------------------------------------------------------------------------------------------------------------------
         */
        
        // This VTBuildingsJAX-RS URL returns the entire data about all of the 115 VT buildings in JSON format
        let vtBuildingsApiURL: URL? = URL(string: "http://orca.cs.vt.edu/VTBuildingsJAX-RS/webresources/vtBuildings/getAll")
        
        /*
         ============================================================
         |        Structure of the JSON data file returned          |
         ============================================================
         
         [      <--- Represents the beginning of the only ARRAY containing 115 dictionary objects.
         
         {      <--- Represents the beginning of a DICTIONARY with KEY : VALUE pairings
         
         "abbreviation":"AGNEW",                                                    <--- VALUE type = String
         "category":"Academic",                                                     <--- VALUE type = String
         "descriptionUrl":"http://manta.cs.vt.edu/vt/buildings/agnew/agnew.txt",    <--- VALUE type = String
         "id":1,                                                                    <--- VALUE type = NSNumber
         "imageUrl":"http://manta.cs.vt.edu/vt/buildings/agnew/agnew.jpg",          <--- VALUE type = String
         "latitude":37.2247741885,                                                  <--- VALUE type = NSNumber
         "longitude":-80.4241237773,                                                <--- VALUE type = NSNumber
         "name":"Agnew Hall"                                                        <--- VALUE type = String
         
         },     <--- Represents the ending of a DICTIONARY with KEY : VALUE pairings
         
         {      <--- Represents the beginning of a DICTIONARY with KEY : VALUE pairings
         
         "abbreviation":"LARNA",
         "category":"Support",
         "descriptionUrl":"http://manta.cs.vt.edu/vt/buildings/larna/larna.txt",
         "id":2,
         "imageUrl":"http://manta.cs.vt.edu/vt/buildings/larna/larna.jpg",
         "latitude":37.2192900000,
         "longitude":-80.4399100000,
         "name":"Alphin-Stuart Livestock Teaching Arena"
         
         },     <--- Represents the ending of a DICTIONARY with KEY : VALUE pairings
         
         :
         :
         
         {      <--- Represents the beginning of a DICTIONARY with KEY : VALUE pairings
         
         "abbreviation":"WRGHT",
         "category":"Academic",
         "descriptionUrl":"http://manta.cs.vt.edu/vt/buildings/wrght/wrght.txt",
         "id":115,
         "imageUrl":"http://manta.cs.vt.edu/vt/buildings/wrght/wrght.jpg",
         "latitude":37.2268104329,
         "longitude":-80.4261888832,
         "name":"Wright House"
         
         }      <--- Represents the ending of a DICTIONARY with KEY : VALUE pairings
         
         ]      <--- Represents the ending of the only ARRAY containing 115 dictionary objects
         
         */
        
        // The JSON data returned from the VTBuildingsJAX-RS RESTful Web Services API is of type NSData
        let jsonData: NSData?
        
        do {
            /*
             Try getting the JSON data from the URL and map it into virtual memory, if possible and safe.
             Option mappedIfSafe indicates that the file should be mapped into virtual memory, if possible and safe.
             */
            jsonData = try NSData(contentsOf: vtBuildingsApiURL!, options: NSData.ReadingOptions.mappedIfSafe)
            
        } catch let error as NSError {
            showAlertMessage(messageHeader: "Unable to Get Data from the Server!",
                             messageBody: "Possible causes: (a) No network connection, (b) Web Service is unavailable, or (c) Server Computer is down. See Error Description: \(error.localizedDescription)")
            return false
        }
        
        if let jsonDataFromApiUrl = jsonData {
            
            // The JSON data is successfully obtained from the API
            
            do {
                /*
                 JSONSerialization class's jsonObject method converts the JSON data into data of type Any.
                 In Swift, the jsonObject method returns a nonoptional result of type Any and is marked
                 with the throws keyword to indicate that it throws an error in cases of failure.
                 */
                let jsonDataArray: Any = try JSONSerialization.jsonObject(with: jsonDataFromApiUrl as Data)
                
                /*
                 We know that the JSON data returned from the VTBuildingsJAX-RS RESTful Web Services API
                 consists of only one ARRAY containing 115 DICTIONARY objects representing 115 VT buildings.
                 Typecast the obtained data of type Any as Array<AnyObject>.
                 */
                let arrayOfVTBuildings = jsonDataArray as! Array<AnyObject>
                
                // Iterate for each of the 115 VT buildings.
                for vtBuilding in arrayOfVTBuildings {
                    
                    // Each object in the arrayOfVTBuildings is a building object of type Dictionary.
                    
                    // Typecast vtBuilding as Dictionary<String, AnyObject> as represented by { and } in the JSON data
                    let dictionaryOfVTBuilding = vtBuilding as! Dictionary<String, AnyObject>
                    
                    //*********************
                    // Obtain Building Name
                    //*********************
                    
                    var buildingName = ""
                    /*
                     IF dictionaryOfVTBuilding["name"] has a value AND the value is of type String THEN
                         unwrap the value and assign it to local variable "name"
                     ELSE show an alert message and stop launching the app.
                     */
                    if let name = dictionaryOfVTBuilding["name"] as! String? {
                        buildingName = name
                    } else {
                        showAlertMessage(messageHeader: "Building Name Missing!",
                                         messageBody: "VTBuildingsJAX-RS API returned JSON data with no building name!")
                        return false
                    }
                    
                    //*********************************
                    // Obtain Abbreviated Building Name
                    //*********************************
                    
                    var abbreviatedBuildingName = ""
                    /*
                     IF dictionaryOfVTBuilding["abbreviation"] has a value AND the value is of type String THEN
                         unwrap the value and assign it to local variable "abbreviatedBuildingName"
                     ELSE show an alert message and stop launching the app.
                     */
                    if let abbreviation = dictionaryOfVTBuilding["abbreviation"] as! String? {
                        abbreviatedBuildingName = abbreviation
                    } else {
                        showAlertMessage(messageHeader: "Abbreviated Building Name Missing!",
                                         messageBody: "VTBuildingsJAX-RS API returned JSON data with no abbreviated building name!")
                        return false
                    }
                    
                    //******************************
                    // Obtain Building Category Name
                    //******************************
                    
                    var buildingCategoryName = ""
                    /*
                     IF dictionaryOfVTBuilding["category"] has a value AND the value is of type String THEN
                         unwrap the value and assign it to local variable "buildingCategoryName"
                     ELSE show an alert message and stop launching the app.
                     */
                    if let category = dictionaryOfVTBuilding["category"] as! String? {
                        buildingCategoryName = category
                    } else {
                        showAlertMessage(messageHeader: "Building Category Missing!",
                                         messageBody: "VTBuildingsJAX-RS API returned JSON data with no building category!")
                        return false
                    }
                    
                    //********************************
                    // Obtain Building Description URL
                    //********************************
                    
                    var buildingDescriptionURL = ""
                    /*
                     IF dictionaryOfVTBuilding["descriptionUrl"] has a value AND the value is of type String THEN
                         unwrap the value and assign it to local variable "buildingDescriptionURL"
                     ELSE show an alert message and stop launching the app.
                     */
                    if let descriptionUrl = dictionaryOfVTBuilding["descriptionUrl"] as! String? {
                        buildingDescriptionURL = descriptionUrl
                    } else {
                        showAlertMessage(messageHeader: "Building Description URL Missing!",
                                         messageBody: "VTBuildingsJAX-RS API returned JSON data with no building description URL!")
                        return false
                    }
                    
                    //**************************
                    // Obtain Building Image URL
                    //**************************
                    
                    var buildingImageURL = ""
                    /*
                     IF dictionaryOfVTBuilding["imageUrl"] has a value AND the value is of type String THEN
                         unwrap the value and assign it to local variable "buildingImageURL"
                     ELSE leave the value as "" since some buildings may not have an image.
                     */
                    if let imageUrl = dictionaryOfVTBuilding["imageUrl"] as! String? {
                        buildingImageURL = imageUrl
                    }
                    
                    //*************************
                    // Obtain Building Latitude
                    //*************************
                    
                    var buildingLatitude: NSNumber?
                    /*
                     IF dictionaryOfVTBuilding["latitude"] has a value AND the value is of type NSNumber THEN
                         unwrap the value and assign it to local variable "buildingLatitude"
                     ELSE show an alert message and stop launching the app.
                     */
                    if let latitude = dictionaryOfVTBuilding["latitude"] as! NSNumber? {
                        buildingLatitude = latitude
                    } else {
                        showAlertMessage(messageHeader: "Building Latitude Missing!",
                                         messageBody: "VTBuildingsJAX-RS API returned JSON data with no building latitude value!")
                        return false
                    }
                    
                    //**************************
                    // Obtain Building Longitude
                    //**************************
                    
                    var buildingLongitude: NSNumber?
                    /*
                     IF dictionaryOfVTBuilding["longitude"] has a value AND the value is of type NSNumber THEN
                         unwrap the value and assign it to local variable "buildingLongitude"
                     ELSE show an alert message and stop launching the app.
                     */
                    if let longitude = dictionaryOfVTBuilding["longitude"] as! NSNumber? {
                        buildingLongitude = longitude
                    } else {
                        showAlertMessage(messageHeader: "Building Longitude Missing!",
                                         messageBody: "VTBuildingsJAX-RS API returned JSON data with no building longitude value!")
                        return false
                    }
                    
                    //************************************
                    // Create a New VT Building Dictionary
                    //************************************
                    
                    // Create a new VT building dictionary with the following KEY : VALUE pairings
                    let vtBuildingDict: [String: AnyObject] = ["abbreviation":      abbreviatedBuildingName as AnyObject,
                                                               "category":          buildingCategoryName    as AnyObject,
                                                               "descriptionUrl":    buildingDescriptionURL  as AnyObject,
                                                               "imageUrl":          buildingImageURL        as AnyObject,
                                                               "latitude":          buildingLatitude        as AnyObject,
                                                               "longitude":         buildingLongitude       as AnyObject,
                                                               ]
                    
                    // Add the new building name to the array of vtBuildingNames
                    self.vtBuildingNames.append(buildingName)
                    
                    /*
                     Add the newly created building dictionary vtBuildingDict to
                     dict_vtBuildingName_vtBuildingDict under the KEY of buildingName
                     */
                    self.dict_vtBuildingName_vtBuildingDict[buildingName] = vtBuildingDict as AnyObject
                }
                
                // Sort vtBuildingNames within itself in alphabetical order
                self.vtBuildingNames.sort { $0 < $1 }
                
                // print(vtBuildingNames)
                
                return true
                
            } catch let error as NSError {
                showAlertMessage(messageHeader: "JSON Data Serialization Failed!",
                                 messageBody: "JSON Data Serialization Error Description: \(error.localizedDescription)")
                return false
            }
            
        } else {
            showAlertMessage(messageHeader: "Unable to Obtain JSON Data!",
                             messageBody: "Possible causes: (a) No network connection, (b) Web Service is unavailable, or (c) Server Computer is down.")
            return false
        }
        
    }
    
    /*
     -----------------------------
     MARK: - Display Alert Message
     -----------------------------
     */
    func showAlertMessage(messageHeader header: String, messageBody body: String) {
        
        /*
         Create a UIAlertController object; dress it up with title, message, and preferred style;
         and store its object reference into local constant alertController
         */
        let alertController = UIAlertController(title: header, message: body, preferredStyle: UIAlertControllerStyle.alert)
        
        // Create a UIAlertAction object and add it to the alert controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Since AppDelegate is not a View Controller, we need to make the window object key and visible
        self.window!.makeKeyAndVisible()
        
        // Display alertController by calling the present method of the window object's rootViewController
        self.window!.rootViewController!.present(alertController, animated: true, completion: nil)
    }
  
}
