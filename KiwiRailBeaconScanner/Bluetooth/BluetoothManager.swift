//
//  BluetoothManager.swift
//  KiwiRail2
//
//  Created by Dylan Carlyle on 29/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    var isAlertPresented = false // Track if an alert is already displayed
    var volt = ""
    var temp = ""
    var nameSpace = ""
    var timestamp: Date?
    
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

    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
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
