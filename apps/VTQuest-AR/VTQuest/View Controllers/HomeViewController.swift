//
//  HomeViewController.swift
//  VTQuest
//
//  Created by Patrick Gatewood on 1/6/18.
//  Copyright © 2018 Osman Balci. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    
    @IBOutlet var vtImageView: UIImageView!
    
    @IBAction func mantaButtonTapped(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "http://manta.cs.vt.edu/balci")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func gatewoodButtonTapped(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "http://patrickgatewood.com")!, options: [:], completionHandler: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        vtImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(HomeViewController.vtLogoTapped(_:))))
    }
    
   @IBAction func vtLogoTapped(_ sender: UITapGestureRecognizer) {
        UIApplication.shared.open(URL(string: "http://vt.edu")!, options: [:], completionHandler: nil)
    }
    
}
