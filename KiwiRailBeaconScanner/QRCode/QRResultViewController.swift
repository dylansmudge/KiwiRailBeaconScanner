//
//  QRResultViewController.swift
//  KiwiRail2
//
//  Created by Dylan Carlyle on 29/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import UIKit
import CoreBluetooth

class QRResultViewController: UIViewController, CBCentralManagerDelegate {
    var qrCodeValue: String?
    
    //UI elements
    @IBOutlet var reportFaultButton: UIButton!
    @IBOutlet var manuallyAddButton: UIButton!
    @IBOutlet var refreshButton: UIButton!
    //Labels
    @IBOutlet weak var nameSpaceLabel: UILabel!
    @IBOutlet weak var instanceLabel: UILabel!
    @IBOutlet weak var voltageLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var shouldPresentAlert = true
    var centralManager: CBCentralManager!
    var isAlertPresented = false // Track if an alert is already displayed
    var volt = ""
    var temp = ""
    var nameSpace = ""
    var timestamp: Date?
    var timeOutInterval = 20.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        if let qrCodeValue = qrCodeValue {
            let parts = qrCodeValue.components(separatedBy: "/")
            if parts.count >= 2 {
                title = parts[0].uppercased()
                nameSpaceLabel.text = parts[0].uppercased()
                instanceLabel.text = parts[1].uppercased()  // Display the second part in part2Label
            } else {
                nameSpaceLabel.text = qrCodeValue
                instanceLabel.text = "No Instance"
            }
        }
       // view.backgroundColor = .white  // Set the background color to white
    }
    
    @IBAction func refreshButtonSelected(_ sender: UIButton) {
        shouldPresentAlert = true
        sender.tintColor = .gray

        // After 5 seconds, revert the color back
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            sender.tintColor = .systemBlue
        }
    }
    
    
    @IBAction func reportFaultButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Report Fault", message: "Please select the type of fault:", preferredStyle: .actionSheet)
        
        let option1Action = UIAlertAction(title: "Battery is Dead", style: .default) { _ in
            // Handle Option 1 selection
        }
        alertController.addAction(option1Action)
        
        let option2Action = UIAlertAction(title: "Physical Damage to Beacon", style: .default) { _ in
            // Handle Option 2 selection
        }
        alertController.addAction(option2Action)
        
        let option3Action = UIAlertAction(title: "Other", style: .default) { _ in
            // Handle Option 3 selection
            self.showReasonAlert()
        }
        alertController.addAction(option3Action)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // For iPad, to avoid a crash due to no source view being provided for popover
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        
        present(alertController, animated: true, completion: nil)
    }
    
    func showReasonAlert() {
        let reasonAlert = UIAlertController(title: "Other Selected", message: "Please provide a reason:", preferredStyle: .alert)
        
        reasonAlert.addTextField { textField in
            textField.placeholder = "Reason"
        }
        
        let okayAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if let reason = reasonAlert.textFields?.first?.text {
                self?.handleOption3Selection(with: reason)
            }
        }
        reasonAlert.addAction(okayAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        reasonAlert.addAction(cancelAction)
        
        present(reasonAlert, animated: true, completion: nil)
    }
    
    func handleOption3Selection(with reason: String) {
        // Handle Option 3 selection with the provided reason
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
                    if !isAlertPresented && shouldPresentAlert {
                        isAlertPresented = true // Set the flag to indicate an alert is being presented
                        
                        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] timer in
                            guard let self = self else { return }
                            let alertController = UIAlertController(title: "Beacon Detected",
                                                                    message:
                                                                        "Namespace: \(nameSpace) \n" +
                                                                    "Voltage: \(volt) mV \n" +
                                                                    "Temperature: \(temp) C \n" +
                                                                    "Signal Strength:\(rssiValue) (\(determineSignalStrength(fromRSSI: rssiValue))) \n" +
                                                                    "Time: \(timeStamp)",
                                                                    preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "Add Data", style: .default) { _ in
                                self.isAlertPresented = false // Reset the flag when the alert is dismissed
                                self.voltageLabel.text = "\(self.volt) mV"
                                self.temperatureLabel.text = "\(self.temp) C"
                                self.timeLabel.text = timeStamp
                                self.shouldPresentAlert = false
                            }
                            let refreshAction = UIAlertAction(title: "Refresh", style: .default) { _ in
                                self.isAlertPresented = false // Reset the flag when the alert is dismissed
                            }
                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                                self.isAlertPresented = false // Reset the flag when the alert is dismissed
                                self.shouldPresentAlert = false
                            }
                            alertController.addAction(okAction)
                            alertController.addAction(refreshAction)
                            alertController.addAction(cancelAction)
                            
                            DispatchQueue.main.async {
                                self.present(alertController, animated: true) {
                                    timer.invalidate() // Invalidate the timer to prevent repeated presentation
                                }
                            }
                            
                            if !shouldPresentAlert && isAlertPresented
                            {
                                //No Signal alert
                                Timer.scheduledTimer(withTimeInterval: timeOutInterval, repeats: false) { [weak self] timer in
                                     guard let self = self else { return }

                                     let noSignalAlertController = UIAlertController(title: "No Bluetooth Signal Detected",
                                                                                   message:
                                                                                "No device detected. Please ensure your bluetooth is enabled. " +
                                                                                "You can report a faulty device, or manually add the device without the telemetry data.",
                                                                                   preferredStyle: .alert)
                                     let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                                         // Handle OK action if needed
                                     }
                                     noSignalAlertController.addAction(okAction)

                                     self.present(noSignalAlertController, animated: true) {
                                         timer.invalidate() // Invalidate the timer to prevent repeated presentation
                                     }
                                 }
                            }
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
        }
        
        func parseEddystoneTLM(_ data: Data) {
            let voltage = UInt16(data[2]) << 8 + UInt16(data[3])
            let temperature = data[4]
            volt = String(voltage)
            temp = String(temperature)
        }
        
    }
}
