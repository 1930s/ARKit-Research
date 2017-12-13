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
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var buildingDescriptionLabel: UILabel!
    @IBOutlet var closeButton: UIButton!
    
    var delegate: BuildingDetailsDelegate?
    
    // Closes the BuildingDetailsView
    @IBAction func close(_ sender: UIButton) {
        if let buildingDetailsDelegate = delegate {
            buildingDetailsDelegate.closeBuildingDetailsView(viewController: self)
        }
    }
    
    // Give the view rounded corners
    override func viewDidLoad() {
        view.layer.cornerRadius = 20;
        view.layer.masksToBounds = true;
    }
}
