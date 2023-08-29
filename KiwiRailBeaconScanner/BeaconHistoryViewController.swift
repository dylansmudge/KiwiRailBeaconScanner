//
//  BeaconHistoryViewController.swift
//  KiwiRail2
//
//  Created by Dylan Carlyle on 25/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import UIKit

class BeaconHistoryViewController: UICollectionViewController {
    
    private let beaconService = BeaconService()
    var orderedMaterials : [ScannedBeacon] = []
    var beaconHistoryCell = BeaconHistoryViewCell()
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ScannedBeacon>
    typealias DataSource = UICollectionViewDiffableDataSource<Section, ScannedBeacon>
    typealias CellRegistration = UICollectionView.CellRegistration<ItemCell, ScannedBeacon>


    
    private lazy var dataSource = makeDataSource()
    
    enum Section {
        case main
    }
    

    
    func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(orderedMaterials, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Beacon History"
        beaconService.loadHistoryData()
        applySnapshot()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, material) -> UICollectionViewCell in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "BeaconHistory",
                    for: indexPath)
                        as? BeaconHistoryViewCell
                else {
                    fatalError("Unable to dequeue item cell")
                }
                let beacon = self.beaconService.beaconHistory[indexPath.row]

                cell.timestampLabel.text = beacon.date
                cell.voltageLabel.text = beacon.voltage
                cell.layer.cornerRadius = 15.0
                
                return cell
            })
        return dataSource
    }
}
    

extension BeaconHistoryViewController {
    /// - Tag: Grid
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(0.2))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        

        return layout
    }
}

