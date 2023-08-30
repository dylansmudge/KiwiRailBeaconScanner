//
//  BeaconProvider.swift
//  KRBeacon
//
//  Created by Dylan Carlyle on 30/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import CoreData
import UIKit

class BeaconProvider {
    private(set) var managedObjectContext: NSManagedObjectContext
    private weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?

    init(with managedObjectContext: NSManagedObjectContext,
         fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?)
    {
        self.managedObjectContext = managedObjectContext
        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
    }

    /**
     A fetched results controller for the NewsPosts entity, sorted by date.
     */
    lazy var fetchedResultsController: NSFetchedResultsController<Beacon> = {
        let fetchRequest: NSFetchRequest<Beacon> = Beacon.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Beacon.namespace), ascending: false)]

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

