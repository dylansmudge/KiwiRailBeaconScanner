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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQRCodeScanner()
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


