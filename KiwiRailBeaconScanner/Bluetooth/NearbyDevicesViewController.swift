//
//  OrderSummaryViewController.swift
//  MiniOrder
//
//  Created by Dylan Carlyle on 11/07/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreData
import UserNotifications


class NearbyDevicesViewController: UICollectionViewController, CBCentralManagerDelegate {
    var timer: Timer?
    
    var orderedMaterials : [ScannedBeacon] = []
    var orderCell = NearbyDevicesCell()
    private let orderService = BeaconService()
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ScannedBeacon>
    typealias DataSource = UICollectionViewDiffableDataSource<Section, ScannedBeacon>
    typealias CellRegistration = UICollectionView.CellRegistration<ItemCell, ScannedBeacon>
    var mV = String()
    var temp = String()
    var centralManager: CBCentralManager!


    
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
        centralManager = CBCentralManager(delegate: self, queue: nil)
        applySnapshot()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate() // Make sure to invalidate the timer when the view controller is about to disappear
    }
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, material) -> UICollectionViewCell in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "NearbyDevices",
                    for: indexPath)
                        as? NearbyDevicesCell
                else {
                    fatalError("Unable to dequeue beacon cell")
                }
                cell.uidLabel.text = "ECA6EA334E9733F361E2"
                cell.voltageLabel?.text = "3102 mV"
                cell.temperatureLabel?.text = "22 C"
                cell.layer.cornerRadius = 15.0
                return cell
            })
        return dataSource
    }
}


extension NearbyDevicesViewController {
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

extension NearbyDevicesViewController {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
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
        let uid = UInt8(data[2])
        print("UID: \(uid)")
    }
    
    func parseEddyStoneURL(_ data: Data) {
        let url = data[2]
        
        print("URL: \(url)")
    }

    
    func parseEddystoneTLM(_ data: Data) {
        let voltage = UInt16(data[2]) << 8 + UInt16(data[3])
        let temperature = data[4]
        mV = String(voltage)
        temp = String(temperature)
        
        print("Eddystone-TLM: Battery Voltage: \(voltage) mV, Temperature: \(temperature) C")
    }
    
    
    func handleEddystoneData(_ data: Data) {
        let frameType = data[0]
        if frameType == 0x00 {  // Eddystone-UID frame type
            parseEddyStoneUID(data)
        } else if frameType == 0x10 { //Eddystone-URL frame type
           parseEddyStoneURL(data)
        }
        else if frameType == 0x20 {  // Eddystone-TLM frame type
            parseEddystoneTLM(data)
        }
        // Handle other Eddystone frame types here
    }
    
    
}
