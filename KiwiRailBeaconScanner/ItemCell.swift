//
//  ItemCell.swift
//  MiniOrder
//
//  Created by Dylan Carlyle on 11/07/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import UIKit
import CoreData

protocol ItemCellDelegate: AnyObject {
    func didUpdateQuantity(_ id: String, _ quantity: Int, _ index: Int)
}

class ItemCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel?
    @IBOutlet weak var orderQuantityLabel: UILabel?
    @IBOutlet var voltageLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    weak var itemCellDelegate : ItemCellDelegate?
    private let beaconService = BeaconService()
    var id = "0"
    var index = 0
    
    //set up for dequeuereusablecollectionviewcell
    //uicontent configuration
    
    // Create a variable to hold the managed object that will be displayed in the cell.
    var managedObject: NSManagedObject?
    
    // Function to configure the cell with data from Core Data
    func configure(with object: NSManagedObject) {
        self.managedObject = object
        
        // Retrieve data from the object and update the UI elements
        if let title = object.value(forKey: "id") as? String {
            label?.text = title
        }
        
    }
                
        var quantity: Int = 0 {
            didSet {
                quantityUpdate()
            }
        }
        
        @IBAction private func increaseButtonTapped(_ sender: UIButton) {
            quantity += 1
        }
        
        @IBAction private func decreaseButtonTapped(_ sender: UIButton) {
            if quantity > 0 {
                quantity -= 1
            }
        }
        
        
        private func quantityUpdate() {
            orderQuantityLabel?.text = "\(quantity)"
            itemCellDelegate?.didUpdateQuantity(id, quantity, index)
        }
        
        func configureQuantity(with text: String) {
            orderQuantityLabel?.text = text
        }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // Customize appearance based on trait collection
    func updateAppearance(for traitCollection: UITraitCollection) {
        if traitCollection.userInterfaceStyle == .dark {
            contentView.backgroundColor = .darkGray
            layer.borderColor = UIColor.clear.cgColor;
            layer.backgroundColor = UIColor.clear.cgColor;
            contentView.layer.cornerRadius = 30.0
            layer.shadowColor = UIColor.lightGray.cgColor;
            layer.shadowOffset = CGSizeMake(0, 1.5);
            layer.shadowRadius = 30.0;
            contentView.layer.shadowOpacity = 0.6;
            contentView.layer.masksToBounds = false;
            contentView.layer.shadowPath = UIBezierPath(roundedRect:bounds, cornerRadius:contentView.layer.cornerRadius).cgPath;
        } else {
            contentView.backgroundColor = .lightGray
        }
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        print(traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular)
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            layout.itemSize = CGSize(width: bounds.width, height: 150)
         } else if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
             layout.itemSize = CGSize(width: bounds.width, height: 150)
         } else {
             // Handle other layouts
         }
    }
}
