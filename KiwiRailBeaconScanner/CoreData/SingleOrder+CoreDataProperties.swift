//
//  SingleOrder+CoreDataProperties.swift
//  MiniOrder
//
//  Created by Dylan Carlyle on 26/07/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//
//

import Foundation
import CoreData


extension SingleOrder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SingleOrder> {
        return NSFetchRequest<SingleOrder>(entityName: "SingleOrder")
    }

    @NSManaged public var id: Int32
    @NSManaged public var quantity: Int32

}

extension SingleOrder : Identifiable {

}
