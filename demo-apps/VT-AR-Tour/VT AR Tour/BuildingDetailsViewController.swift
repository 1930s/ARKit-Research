//
//  BuildingDetailsViewController.swift
//  VT AR Tour
//
//  Created by Patrick Gatewood on 11/21/17.
//  Copyright © 2017 Patrick Gatewood. All rights reserved.
//

import UIKit

protocol BuildingDetailsDelegate {
    func closeBuildingDetailsView(viewController: UIViewController)
}

class BuildingDetailsViewController: UIViewController {
    
    @IBOutlet var buildingNameLabel: UILabel!
    @IBOutlet var buildingImageview: UIImageView!
    @IBOutlet var buildingDescriptionLabel: UILabel!
    
    var delegate: BuildingDetailsDelegate?
    
    @IBAction func close(_ sender: UIButton) {
        print("called")
       
        if let buildingDetailsDelegate = delegate {
            buildingDetailsDelegate.closeBuildingDetailsView(viewController: self)
        }
    }
}
