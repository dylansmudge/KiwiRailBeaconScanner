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
    @NSManaged public var voltage: Int16
    @NSManaged public var temperature: Int16
    @NSManaged public var time: String?

}

extension Beacon : Identifiable {

}
