//
//  OrderCell.swift
//  MiniOrder
//
//  Created by Dylan Carlyle on 13/07/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import UIKit
import CoreBluetooth

class NearbyDevicesCell: UICollectionViewCell, CBCentralManagerDelegate {
    @IBOutlet var voltageLabel: UILabel?
    @IBOutlet var temperatureLabel: UILabel?
    @IBOutlet var uidLabel: UILabel!
    var timer: Timer?
    var centralManager: CBCentralManager!

    @IBOutlet var saveButton: UIButton!
    
    @IBAction func saved(_ sender: Any) {
    }
}

extension NearbyDevicesCell {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            for (uuid, data) in serviceData {
                let uuidString = uuid.uuidString.lowercased()
                if uuidString == "feaa" {  // Eddystone UUID
                    switch data[0] {
                    case 0x00:
                        parseEddyStoneUID(data)
                    case 0x10:
                        parseEddyStoneURL(data)
                    case 0x20:
                        parseEddystoneTLM(data)
                    default:
                        print("Trying to scan for beacons...")
                    }
                }
            }
        }
    }
    
    func parseEddyStoneUID(_ data: Data) {
        let uid = UInt8(data[2])
        print("UID: \(uid)")
    }
    
    func parseEddyStoneURL(_ data: Data) {
        let url = data[2]
        
        print("URL: \(url)")
    }

    
    func parseEddystoneTLM(_ data: Data) {
        let voltage = UInt16(data[2]) << 8 + UInt16(data[3])
        let temperature = data[4]
        print("Eddystone-TLM: Battery Voltage: \(voltage) mV, Temperature: \(temperature) C")
    }
    
    
    func handleEddystoneData(_ data: Data) {
        let frameType = data[0]
        if frameType == 0x00 {  // Eddystone-UID frame type
            parseEddyStoneUID(data)
        } else if frameType == 0x10 { //Eddystone-URL frame type
           parseEddyStoneURL(data)
        }
        else if frameType == 0x20 {  // Eddystone-TLM frame type
            parseEddystoneTLM(data)
        }
        // Handle other Eddystone frame types here
    }
    
    
}

