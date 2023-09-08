//
//  WagonBeaconPlacementViewController.swift
//  KRBeacon
//
//  Created by Dylan Carlyle on 5/09/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import UIKit

class WagonBeaconPlacementViewController: UIViewController {
    @IBOutlet weak var locationPickerView: UIPickerView! // Connect this to your UIPickerView in the storyboard
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBAction func onSelect(_ sender: Any) {
        let reviewBeaconsViewController = self.storyboard?.instantiateViewController(withIdentifier: "ReviewBeaconsViewController") as! ReviewBeaconsViewController
        self.navigationController?.pushViewController(reviewBeaconsViewController, animated: true)
        performSegue(withIdentifier: "showReviewBeacons", sender: self)
    }
    let locationDataSource = LocationDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        locationPickerView.dataSource = locationDataSource
        locationPickerView.delegate = locationDataSource
    }
}
