//
//  BeaconService.swift
//  KiwiRail2
//
//  Created by Dylan Carlyle on 23/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import CoreData

class BeaconService {
    
    var beacons = [Beacon]()
    var beaconHistory = [HistoricalBeacon]()
    var selectedImage: String?
    
    var orderedMaterials = [String: ScannedBeacon]()
    
    
    // MARK: - JSON
    
    func readLocalJSONFile(forName name: String) -> Data? {
        do {
            if let filePath = Bundle.main.path(forResource: name, ofType: "json") {
                let fileUrl = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: fileUrl)
                return data
            }
        } catch {
            print("error: \(error)")
        }
        return nil
    }
    
    func parse(jsonData: Data) -> Beacons? {
        do {
            let decodedData = try JSONDecoder().decode(Beacons.self, from: jsonData)
            return decodedData
        } catch {
            print("error: \(error)")
        }
        return nil
    }
    
    func loadData(){
        let jsonData = readLocalJSONFile(forName: "beacons")
        if let data = jsonData {
            if let beacons = parse(jsonData: data) {
                self.beacons = beacons.beacons
            }
        }
        loadCoreData()
    }
    
    func parseHistory(jsonData: Data) -> HistoricalBeacons? {
        do {
            let decodedData = try JSONDecoder().decode(HistoricalBeacons.self, from: jsonData)
            return decodedData
        } catch {
            print("error: \(error)")
        }
        return nil
    }

    
    func loadHistoryData(){
        let jsonData = readLocalJSONFile(forName: "beaconHistory")
        if let data = jsonData {
            if let beacons = parseHistory(jsonData: data) {
                self.beaconHistory = beacons.historicalBeacons
            }
        }
    }
    
    func loadCoreData(){
        let fetchRequest = SingleOrder.createFetchRequest()
        let context = CoreDataStack.shared.viewContext
        let entities = try? context.fetch(fetchRequest)
        entities?.forEach({ singleOrder in
            var orderedMaterial: ScannedBeacon
            if let existingOrderMaterial = orderedMaterials[singleOrder.id]
            {
                orderedMaterial = existingOrderMaterial
            }
            else
            {
                orderedMaterial = ScannedBeacon(id: singleOrder.id, quantity: Int(singleOrder.quantity), index: 0)
            }
            orderedMaterial.quantity = Int(singleOrder.quantity)
            orderedMaterials[orderedMaterial.id] = orderedMaterial
        })
    }
    
    func saveQuantityToStore(_ id: String, _ quantity: Int)
    {
        let fetchRequest = SingleOrder.createFetchRequest()
        fetchRequest.predicate = NSPredicate.init(format: "id = %@", id)
        let context = CoreDataStack.shared.viewContext
        let entity: SingleOrder
        if let fetchedEntity = (try? context.fetch(fetchRequest))?.first {
            entity = fetchedEntity
        }
        else {
            entity = SingleOrder.init(context: context)
            entity.id = id
        }
        entity.quantity = Int32(quantity)
        try? context.save()
    }
    
    
    func saveQuantity(_ id: String, _ quantity: Int, _ index: Int) {
        if var orderedMaterial = orderedMaterials[id] {
            orderedMaterial.quantity = quantity
            orderedMaterial.index = index
            orderedMaterials[id] = orderedMaterial
        }
        else {
            orderedMaterials[id] = ScannedBeacon(id: id, quantity: quantity, index: index)
        }
        saveQuantityToStore(id, quantity)
    }
    
    func retrieveQuantity(id: String) -> Int {
        guard let validQuantity = orderedMaterials[id]
        else {
            return 0
        }
        return validQuantity.quantity
    }
    
}
