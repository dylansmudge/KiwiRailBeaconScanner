//
//  EmailService.swift
//  KRBeacon
//
//  Created by Dylan Carlyle on 4/09/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import MessageUI

class EmailService: UIViewController, MFMailComposeViewControllerDelegate {
    
    // MARK: Email functionality
    func sendEmail(with reason: String) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["dylan@smudge.com"]) // Set the recipient email address
            mailComposer.setSubject("KiwiRail Beacon error")
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
    
}

