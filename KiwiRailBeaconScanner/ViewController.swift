//
//  ViewController.swift
//  KiwiRail2
//
//  Created by Dylan Carlyle on 23/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UICollectionViewController, ItemCellDelegate, NSFetchedResultsControllerDelegate {
    
    private let beaconService = BeaconService()
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Beacon>
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Beacon>
    typealias CellRegistration = UICollectionView.CellRegistration<ItemCell, Beacon>
    private lazy var dataSource = makeDataSource()
    
    enum Section {
        case main
    }
    
    func didUpdateQuantity(_ id: String, _ quantity: Int, _ index: Int) {
        beaconService.saveQuantity(id, quantity, index)
    }
    
    func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(beaconService.beacons, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        for case let cell as ItemCell in collectionView.visibleCells {
            cell.updateAppearance(for: traitCollection)
        }
        
    }
    
    override public var traitCollection: UITraitCollection {
        if UIDevice.current.userInterfaceIdiom == .pad && UIDevice.current.orientation.isPortrait {
            return UITraitCollection(traitsFrom:[UITraitCollection(horizontalSizeClass: .regular), UITraitCollection(verticalSizeClass: .regular)])
        }
        return super.traitCollection
    }
    
    /**
     You create a dataSource, passing in collectionView and a cellProvider callback.
     Inside the cellProvider callback, you return an ItemCell.
     The code you write in this function is the same as you’re used to seeing in
     UICollectionViewDataSource‘s collectionView(_:cellForItemAt:).
     */
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { [self] (collectionView, indexPath, material) -> UICollectionViewCell in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "Item",
                    for: indexPath)
                        as? ItemCell
                else {
                    fatalError("Unable to dequeue item cell")
                }
                //--try using collectionview.dequeueconfiguredreusablecell
                cell.updateAppearance(for: traitCollection)
                
                cell.itemCellDelegate = self
                
                let beacon = beaconService.beacons[indexPath.row]
                cell.label?.text = beacon.displayName
                cell.dateLabel.text = beacon.date
                cell.voltageLabel.text = beacon.voltage
                
                cell.id = String(material.id)
                cell.index = indexPath.row
                
                
                let defaults = UserDefaults.standard
                let text = "\(cell.quantity)"
                defaults.set(text, forKey: "text")
                
                //Apply custom design
                cell.layer.cornerRadius = 30.0
                cell.contentView.layer.borderColor = UIColor.clear.cgColor;
                cell.contentView.layer.masksToBounds = true;
                cell.contentView.layer.cornerRadius = 30.0
                cell.layer.shadowColor = UIColor.lightGray.cgColor;
                cell.layer.shadowOffset = CGSizeMake(0, 1.5);
                cell.layer.shadowRadius = 30.0;
                cell.layer.shadowOpacity = 0.8;
                cell.layer.masksToBounds = false;
                cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath;
                
                return cell
            })
        return dataSource
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        beaconService.loadData()
        navigationItem.title = "Beacon"
        applySnapshot()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNearbyDevicesSegue" {
        }
        else if segue.identifier == "showCameraSegue" {
            
        }
    }
}
