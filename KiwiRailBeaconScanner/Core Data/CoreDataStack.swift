//
//  CoreDataStack.swift
//  MiniOrder
//
//  Created by Dylan Carlyle on 1/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Beacon")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // You can also add a background context for performing background tasks if needed.

    private init() {}
}
