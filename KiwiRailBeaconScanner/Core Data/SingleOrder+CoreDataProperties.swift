//
//  SingleOrder+CoreDataProperties.swift
//  MiniOrder
//
//  Created by Dylan Carlyle on 1/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//
//

import Foundation
import CoreData


extension SingleOrder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SingleOrder> {
        return NSFetchRequest<SingleOrder>(entityName: "SingleOrder")
    }

    @NSManaged public var id: String
    @NSManaged public var quantity: String

}

extension SingleOrder : Identifiable {

}
