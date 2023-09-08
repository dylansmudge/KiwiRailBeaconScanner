//
//  QRResultViewController.swift
//  KiwiRail2
//
//  Created by Dylan Carlyle on 29/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreData
import MessageUI

class QRResultViewController: UIViewController, CBCentralManagerDelegate, NSFetchedResultsControllerDelegate, MFMailComposeViewControllerDelegate {

    
    //Buttons
    @IBOutlet var reportFaultButton: UIButton!
    @IBOutlet var manuallyAddButton: UIButton!
    @IBOutlet var refreshButton: UIButton!
    //Labels
    @IBOutlet weak var nameSpaceLabel: UILabel!
    @IBOutlet weak var instanceLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet var beaconView: UIView!
    //Symbols
    @IBOutlet weak var loadingSymbol: UIActivityIndicatorView!
    
    @IBOutlet var batteryView: LevelView!
    
    
    lazy var dataProvider: BeaconProvider = {
        let managedContext = AppDelegate.sharedAppDelegate.coreDataStack.managedContext
        let provider = BeaconProvider(with: managedContext, fetchedResultsControllerDelegate: self)
        return provider
    }()
    
    //Variables
    var shouldPresentAlert = true
    var centralManager: CBCentralManager!
    var isAlertPresented = false // Track if an alert is already displayed
    var beaconDetected = false
    var volt = ""
    var temp = ""
    var nameSpace = ""
    var instance = ""
    var timestamp: Date?
    var timeOutInterval = 1.0
    var battery: Double = 0.0
    var qrCodeValue: String?
    var rssiUID: Int64 = 0
    var rssiTLM: Int64 = 0
    var peripheralUID: String?
    var peripheralTLM: String?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        // Start animating the indicator
        loadingSymbol.startAnimating()
        if let qrCodeValue = qrCodeValue {
            let parts = qrCodeValue.components(separatedBy: "/")
            if parts.count >= 2 {
                title = "Scanning for Telemetry"
                nameSpaceLabel.text = parts[0].uppercased()
                instanceLabel.text = parts[1].uppercased() 
            } else {
                nameSpaceLabel.text = nameSpace
                instanceLabel.text = instance
                temperatureLabel.text = "\(temp) C"
                timeLabel.text = generateTimestamp()
                batteryView.batteryLevel = battery / 100
                shouldPresentAlert = false
                self.loadingSymbol.stopAnimating()
                self.loadingSymbol.isHidden = true
                centralManager.stopScan()
            }
        }
    }
    
    @IBAction func refreshButtonSelected(_ sender: UIButton) {
        shouldPresentAlert = true
        sender.tintColor = .gray
        self.loadingSymbol.startAnimating()
        self.loadingSymbol.isHidden = false
        startBluetoothScan()
        // After 1 second, revert the color back
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            sender.tintColor = .systemBlue
            self.loadingSymbol.stopAnimating()
            self.loadingSymbol.isHidden = true
        }
    }
    
    @IBAction func saveButtonSelected(_ sender: UIButton) {
        sendEmailSuccess(with: nameSpace, instance: instance, battery: battery, temperature: temp, timeStamp: timestamp)
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
        switch result {
        case .cancelled:
            // Handle the email being canceled
            print("Email composition canceled.")
        case .saved:
            // Handle the email being saved as a draft
            print("Email saved as draft.")
        case .sent:
            // Handle the email being sent successfully
            print("Email sent successfully.")
        case .failed:
            // Handle the email sending failure
            print("Email sending failed.")
        @unknown default:
            break
        }
    }
    
    // MARK: Email functionality
    func sendEmailSuccess(with nameSpace: String, instance: String, battery: Double, temperature: String, timeStamp: Date?) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["dylan@smudge.com"]) // Set the recipient email address
            mailComposer.setSubject("KiwiRail Beacon Scanned Successfully: \(nameSpace)")
            mailComposer.setMessageBody("KiwiRail Beacon Scanned Successfully. \n Beacon Info: \n" +
                                        " Namespace: \(nameSpace) \n" +
                                        " Instance: \(instance) \n" +
                                        " Battery: \(Int(battery))% \n" +
                                        " Temperature: \(temperature) C \n " +
                                        " TimeStamp: \(timeStamp ?? Date())\n"
                                        , isHTML: false)
            
            present(mailComposer, animated: true, completion: nil)
        } else {
            // Device cannot send email, handle this case
            let alertController = UIAlertController(
                title: "Cannot Send Email",
                message: "Your device is not configured to send email.",
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func sendEmailFault(with reason: String, nameSpace: String) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["dylan@smudge.com"]) // Set the recipient email address
            mailComposer.setSubject("KiwiRail Beacon Error Report: \(nameSpace)")
            mailComposer.setMessageBody("An error has been reported on one of the devices. \n" +
                                        "Beacon Namespace: \(nameSpace)\n" +
                                         "Given Reason: \n   \(reason)", isHTML: false)
            
            present(mailComposer, animated: true, completion: nil)
        } else {
            // Device cannot send email, handle this case
            let alertController = UIAlertController(
                title: "Cannot Send Email",
                message: "Your device is not configured to send email.",
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func reportFaultButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Report Fault", message: "Please select the type of fault:", preferredStyle: .actionSheet)
        
        let option1Action = UIAlertAction(title: "Battery is Dead", style: .default) { _ in
            // Handle Option 1 selection
            let reason = "Battery is Dead"
            self.handleOption2Selection(with: reason)
        }
        alertController.addAction(option1Action)
        
        let option2Action = UIAlertAction(title: "Physical Damage to Beacon", style: .default) { _ in
            // Handle Option 2 selection
            let reason = "Physical Damage to Beacon"
            self.handleOption2Selection(with: reason)
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
    
    // MARK: Handle Reasons Selected
    
    func handleOption1Selection(with reason: String) {
        self.sendEmailFault(with: reason, nameSpace: nameSpace)

    }
    
    func handleOption2Selection(with reason: String) {
        self.sendEmailFault(with: reason, nameSpace: nameSpace)

    }
        
    func handleOption3Selection(with reason: String) {
        // Handle Option 3 selection with the provided reason
        self.sendEmailFault(with: reason, nameSpace: nameSpace)
    }
    
    enum RSSISignalStrength: String {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case weak = "Weak"
        case unknown = "Unknown"
    }
    
    func determineSignalStrength(fromRSSI rssiValue: Int) -> RSSISignalStrength {
        if rssiTLM - rssiUID < 10 {
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
        else {
            return .unknown
        }
    }
    
    func startBluetoothScan() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            // Handle discovered peripherals in centralManager delegate methods
        } else {
            print("Bluetooth is not powered on.")
            // Handle if Bluetooth is not powered on
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
                let rssiValue = RSSI.intValue
                let uuidString = uuid.uuidString.lowercased()
                if uuidString == "feaa" {  // Eddystone UUID
                    beaconDetected = true
                    switch data[0] {
                    case 0x00:
                        rssiUID = Int64(rssiValue)
                        peripheralUID = "\(peripheral.identifier)"
                        parseEddyStoneUID(data)
                    case 0x10:
                        parseEddyStoneURL(data)
                    case 0x20:
                        rssiTLM = Int64(rssiValue)
                        peripheralTLM = "\(peripheral.identifier)"
                        parseEddystoneTLM(data)
                    default:
                        print("Trying to scan for beacons...")
                    }
                    if peripheralTLM == peripheralUID {
                        let timeStamp = generateTimestamp()
                        self.isAlertPresented = false // Reset the flag when the alert is dismissed
                        self.instanceLabel.text = "\(self.instance)"
                        self.temperatureLabel.text = "\(self.temp) C"
                        self.timeLabel.text = timeStamp
                        self.shouldPresentAlert = false
                        self.batteryView.batteryLevel = (self.battery / 100)
                        self.centralManager.stopScan()
                        self.loadingSymbol.stopAnimating()
                        self.loadingSymbol.isHidden = true
                    }
                    if beaconDetected == false
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
        
        
        func parseEddyStoneUID(_ data: Data) {
            let byteArray = [UInt8](data) // Convert Data to [UInt8] array
            let combinedUIDHexString = combineArrayValuesToString(from: byteArray, startIndex: 1, endIndex: 10)
            nameSpace = combinedUIDHexString
            let combinedInstanceHexString = combineArrayValuesToString(from: byteArray, startIndex: 11, endIndex: 16)
            instance = combinedInstanceHexString

        }
        
        func combineArrayValuesToString(from data: [UInt8], startIndex: Int, endIndex: Int) -> String {
            let subArray = Array(data[startIndex..<endIndex+1])
            let hexString = subArray.map { String(format: "%02X", $0) }.joined(separator: "")
            return hexString
        }
        
        func parseEddyStoneURL(_ data: Data) {
            _ = data[2]
        }
        
        func parseEddystoneTLM(_ data: Data) {
            let voltage = UInt16(data[2]) << 8 + UInt16(data[3])
            let temperature = data[4]
            volt = String(voltage)
            temp = String(temperature)
            battery = (Double(voltage) / 3200) * 100
        }
    }
}
