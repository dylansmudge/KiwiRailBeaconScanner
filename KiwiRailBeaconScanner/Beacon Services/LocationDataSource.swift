//
//  LocationDataSource.swift
//  KRBeacon
//
//  Created by Dylan Carlyle on 5/09/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class LocationDataSource: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    let locations = ["Auckland", "Tauranga", "Hamilton", "Palmerston North", "Wellington", "Nelson", "Christchurch", "Dunedin", "Invercargill"] // Replace with your location data

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // We're using a single component (column) in the picker.
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return locations.count // Number of rows in the picker.
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return locations[row] // Return the location data for the specified row.
    }
}
