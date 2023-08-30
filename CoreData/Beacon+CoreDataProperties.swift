//
//  Beacon+CoreDataProperties.swift
//  KRBeacon
//
//  Created by Dylan Carlyle on 30/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//
//

import Foundation
import CoreData


extension Beacon {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Beacon> {
        return NSFetchRequest<Beacon>(entityName: "Beacon")
    }

    @NSManaged public var namespace: String?
    @NSManaged public var instance: String?
    @NSManaged public var voltage: Int32
    @NSManaged public var temperature: Int32
    @NSManaged public var time: String?
    
    internal class func createOrUpdate(item: BeaconModelItem, with stack: CoreDataStack) {
        let beaconItemNamespace = item.namespace
        var currentBeacon: Beacon? // Entity name
        let beaconPostFetch: NSFetchRequest<Beacon> = Beacon.fetchRequest()
        if let beaconItemNamespace = beaconItemNamespace {
            let beaconItemNamespacePredicate = NSPredicate(format: "%K == %i", #keyPath(Beacon.namespace), beaconItemNamespace)
            beaconPostFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [beaconItemNamespacePredicate])
        }
        do {
            let results = try stack.managedContext.fetch(beaconPostFetch)
            if results.isEmpty {
                // Beacon post not found, create a new.
                currentBeacon = Beacon(context: stack.managedContext)
                if let beaconNamespace = beaconItemNamespace {
                    currentBeacon?.namespace = beaconNamespace
                }
            } else {
                // News post found, use it.
                currentBeacon = results.first
            }
            currentBeacon?.update(item: item)
        } catch let error as NSError {
            print("Fetch error: \(error) description: \(error.userInfo)")
        }
    }

    internal func update(item: BeaconModelItem) {
        // Namespace
        self.namespace = item.namespace
        // Instance
        self.instance = item.instance
        // Voltage
        self.voltage = item.voltage ?? 0
        // Temperature
        self.temperature = item.temp ?? 0
        // Time
        self.time = item.time
    }

}

extension Beacon : Identifiable {

}
