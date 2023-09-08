//
//  cameraViewController.swift
//  KiwiRail2
//
//  Created by Dylan Carlyle on 25/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreBluetooth
import MessageUI




class CameraViewController: UIViewController,  AVCaptureMetadataOutputObjectsDelegate, CBCentralManagerDelegate, MFMailComposeViewControllerDelegate {
    
    
    // MARK: Variables
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
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var timer: Timer?
    var qrCodeFrameView: UIView?
    
    @IBOutlet var reportFaultButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQRCodeScanner()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: Email functionality

    
    func sendEmailFault(with reason: String) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["dylan@smudge.com"]) // Set the recipient email address
            mailComposer.setSubject("KiwiRail Beacon Error Report")
            mailComposer.setMessageBody("An error has been reported on one of the devices. \n Given Reason: \n \(reason)", isHTML: false)
            
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
    
    // UIImagePickerControllerDelegate method to handle user's photo selection
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Attach the selected image to the email
            if let mailComposer = self.presentedViewController as? MFMailComposeViewController {
                if let imageData = selectedImage.jpegData(compressionQuality: 1.0) {
                    mailComposer.addAttachmentData(imageData, mimeType: "image/jpeg", fileName: "photo.jpg")
                }
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: Fault Reporting
    
    @IBAction func reportFaultButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Report Fault", message: "Please select the type of fault:", preferredStyle: .actionSheet)
        
        let option1Action = UIAlertAction(title: "Cannot scan Beacon", style: .default) { _ in
            // Handle Option 1 selection
            let reason = "Cannot scan Beacon"
            self.handleOption1Selection(with: reason)
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
        self.sendEmailFault(with: reason)

    }
    
    func handleOption2Selection(with reason: String) {
        self.sendEmailFault(with: reason)

    }
        
    func handleOption3Selection(with reason: String) {
        // Handle Option 3 selection with the provided reason
        self.sendEmailFault(with: reason)
    }
    
    
    // MARK: Camera Functionality
    
    func setupQRCodeScanner() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            fatalError("No video capture device available.")
        }
        
        captureSession.sessionPreset = .high // Configure the session preset
        // 1
        for vFormat in captureDevice.formats {
            
            // 2
            var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
            var frameRates = ranges[0]
            
            // 3
            if frameRates.maxFrameRate == 240 {
                
                // 4
                do {
                    try captureDevice.lockForConfiguration()
                }
                catch {
                    return
                }
                captureDevice.activeFormat = vFormat as AVCaptureDevice.Format
                captureDevice.activeVideoMinFrameDuration = frameRates.minFrameDuration
                captureDevice.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                captureDevice.unlockForConfiguration()
                
            }
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        captureSession.startRunning()
    }
    
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let qrCodeValue = metadataObject.stringValue {
            openQRResultViewController(with: qrCodeValue, nameSpace: nameSpace, Instance: instance, Battery: battery, Temperature: temp, TimeStamp: timestamp)
        }
    }
    
    func openQRResultViewController(with qrCodeValue: String, nameSpace: String, Instance: String, Battery: Double, Temperature: String, TimeStamp: Date?) {
        let storyboard = UIStoryboard(name: "QRResultContentView", bundle: nil) // Replace "Main" with your storyboard's name
        if let qrResultViewController = storyboard.instantiateViewController(withIdentifier: "QRResultView") as? QRResultViewController {
            qrResultViewController.qrCodeValue = qrCodeValue
            qrResultViewController.nameSpace = nameSpace
            qrResultViewController.instance = instance
            qrResultViewController.battery = battery
            qrResultViewController.temp = temp
            qrResultViewController.timestamp = timestamp
            navigationController?.pushViewController(qrResultViewController, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCaptureSession()
        centralManager.stopScan()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCaptureSession()
    }
    
    
    func stopCaptureSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func startCaptureSession() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    
    
    
    
    // MARK: Bluetooth
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
                        self.openQRResultViewController(with: nameSpace, nameSpace: nameSpace, Instance: instance, Battery: battery, Temperature: temp, TimeStamp: timestamp)
                        self.centralManager.stopScan()
                    }
                    if beaconDetected == false
                    {
                        //No Bluetooth signal detected alert
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
            let combinedHexString = combineArrayValuesToString(from: byteArray, startIndex: 1, endIndex: 10)
            nameSpace = combinedHexString
            let combinedInstanceHexString = combineArrayValuesToString(from: byteArray, startIndex: 11, endIndex: 16)
            instance = combinedInstanceHexString
            print("Namespace: \(nameSpace)")
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


