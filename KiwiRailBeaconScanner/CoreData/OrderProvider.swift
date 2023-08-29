//
//  OrderProvider.swift
//  MiniOrder
//
//  Created by Dylan Carlyle on 31/07/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class OrderProvider {
    private(set) var managedObjectContext: NSManagedObjectContext
    private weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?

    init(with managedObjectContext: NSManagedObjectContext,
         fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?)
    {
        self.managedObjectContext = managedObjectContext
        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
    }

    /**
     A fetched results controller for the SingleOrder entity, sorted by quantity.
     */
    lazy var fetchedResultsController: NSFetchedResultsController<SingleOrder> = {
        let fetchRequest: NSFetchRequest<SingleOrder> = SingleOrder.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(SingleOrder.quantity), ascending: false)]

        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest, managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        controller.delegate = fetchedResultsControllerDelegate

        do {
            try controller.performFetch()
        } catch {
            print("Fetch failed")
        }

        return controller
    }()
}

