//
//  BluetoothViewController.swift
//  KiwiRail2
//
//  Created by Dylan Carlyle on 29/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class BluetoothViewController: UIViewController, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var isAlertPresented = false // Track if an alert is already displayed
    var volt = ""
    var temp = ""
    var nameSpace = ""
    var timestamp: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    enum RSSISignalStrength: String {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case weak = "Weak"
        case unknown = "Unknown"
    }

    func determineSignalStrength(fromRSSI rssiValue: Int) -> RSSISignalStrength {
        switch rssiValue {
            case -50...0:
                return .excellent
            case -60..<(-50):
                return .good
            case -70..<(-60):
                return .fair
            case -80..<(-70):
                return .weak
            default:
                return .unknown
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func generateTimestamp() -> String {
        let timestamp = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedTimestamp = dateFormatter.string(from: timestamp)
        return formattedTimestamp
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
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
                    let rssiValue = RSSI.intValue
                    let timeStamp = generateTimestamp()
                    if !isAlertPresented {
                        isAlertPresented = true // Set the flag to indicate an alert is being presented
                        let alertController = UIAlertController(title: "Bluetooth Device Detected",
                                                                message: 
                                                                "Namespace: \(nameSpace) \n" +
                                                                "Voltage: \(volt) mV \n" +
                                                                "Temperature: \(temp) C \n" +
                                                                "Signal Strength:\(rssiValue) (\(determineSignalStrength(fromRSSI: rssiValue))) \n" +
                                                                "Time: \(timeStamp)",
                                                                preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Save", style: .default) { _ in
                            self.isAlertPresented = false // Reset the flag when the alert is dismissed
                        }
                        let refreshAction = UIAlertAction(title: "Refresh", style: .default) { _ in
                            self.isAlertPresented = false // Reset the flag when the alert is dismissed
                        }
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                            self.isAlertPresented = false // Reset the flag when the alert is dismissed
                        }
                        alertController.addAction(okAction)
                        alertController.addAction(refreshAction)
                        alertController.addAction(cancelAction)

                        DispatchQueue.main.async {
                            self.present(alertController, animated: true, completion: nil)
                        }
                        print(advertisementData)

                    }
                }
            }
        }

    }
    
    
    func parseEddyStoneUID(_ data: Data) {
        let byteArray = [UInt8](data) // Convert Data to [UInt8] array
        let combinedHexString = combineArrayValuesToString(from: byteArray, startIndex: 1, endIndex: 10)
        nameSpace = combinedHexString
    }
    
    func combineArrayValuesToString(from data: [UInt8], startIndex: Int, endIndex: Int) -> String {
        let subArray = Array(data[startIndex..<endIndex+1])
        let hexString = subArray.map { String(format: "%02X", $0) }.joined(separator: "")
        return hexString
    }
    
    func parseEddyStoneURL(_ data: Data) {
        let url = data[2]
        
        print("URL: \(url)")
    }

    
    func parseEddystoneTLM(_ data: Data) {
        let voltage = UInt16(data[2]) << 8 + UInt16(data[3])
        let temperature = data[4]
        volt = String(voltage)
        temp = String(temperature)
    }
    
    
}
