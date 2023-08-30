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


class CameraViewController: UIViewController,  AVCaptureMetadataOutputObjectsDelegate{
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var timer: Timer?
    var qrCodeFrameView: UIView?
    @IBOutlet var reportFaultButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQRCodeScanner()
    }
    

    @IBAction func reportFaultButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Report Fault", message: "Please select the type of fault:", preferredStyle: .actionSheet)
        
        let option1Action = UIAlertAction(title: "Cannot scan Beacon", style: .default) { _ in
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
            showQRCodeAlert(qrCodeValue)
        }
    }
    
    func showQRCodeAlert(_ qrCodeValue: String) {
        let parts = qrCodeValue.components(separatedBy: "/")
        let alert = UIAlertController(title: "QR Code Detected", message: parts[0].uppercased(), preferredStyle: .alert)
        let addAction = UIAlertAction(title: "Add", style: .default)
        { _ in
                self.openQRResultViewController(with: qrCodeValue)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func openQRResultViewController(with qrCodeValue: String) {
        let storyboard = UIStoryboard(name: "QRResultContentView", bundle: nil) // Replace "Main" with your storyboard's name
        if let qrResultViewController = storyboard.instantiateViewController(withIdentifier: "QRResultView") as? QRResultViewController {
            qrResultViewController.qrCodeValue = qrCodeValue
            navigationController?.pushViewController(qrResultViewController, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCaptureSession()
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
    
}


