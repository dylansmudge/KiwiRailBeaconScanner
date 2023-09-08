//
//  ReviewBeaconsViewController.swift
//  KRBeacon
//
//  Created by Dylan Carlyle on 6/09/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation
import UIKit

class ReviewBeaconsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Variables
    let tableViewData = Array(repeating: "Item", count: 20)
    var items = Array(repeating: "Item", count: 20)    
    var currentPage = 1
    let itemsPerPage = 5// Number of items to load per page
    var isLoading = false // Used to prevent multiple loading requests
    let sortTableViewData = ["A-Z", "Z-A", "Latest", "Oldest", "One", "Two"]
    
    // MARK: Outlets
    @IBOutlet weak var beaconsTableView: UITableView!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var sortTableView: UITableView!
    
    @IBAction func pullDownButtonTapped(_ sender: UIButton) {
        // Show/hide the UITableView when the button is tapped
        sortTableView.isHidden = !sortTableView.isHidden
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        beaconsTableView.delegate = self
        beaconsTableView.dataSource = self
        
        
        sortTableView.dataSource = self
        sortTableView.delegate = self
        
        // Show a default selection
        let defaultSelection = sortTableViewData.first ?? ""
        sortButton.setTitle(defaultSelection, for: .normal)
        sortTableView.register(SortByTableViewCell.self, forCellReuseIdentifier: "SortByTableViewCell")
        loadInitialData()
    }
    
    
    // MARK: Table View
    func loadInitialData() {
        isLoading = true
        
        beaconsTableView.reloadData()
        sortTableView.reloadData()
        isLoading = false
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == beaconsTableView {
            return items.count
        }
        else if tableView == sortTableView {
            return sortTableViewData.count
        }
        return Int()
    }
    
    // Dequeue and configure your custom cell in cellForRowAtIndexPath
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == beaconsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BeaconsTableViewCell", for: indexPath) as! BeaconsTableViewCell
            // Configure your cell with data here
            return cell
        }
        if tableView == sortTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SortByTableViewCell", for: indexPath) as! SortByTableViewCell
            
            print("Configuring cell at indexPath: \(sortTableViewData[indexPath.row])")
            // Use optional binding to safely access sortLabel
                if let sortLabel = cell.sortLabel {
                    sortLabel.text = "\(sortTableViewData[indexPath.row])"
                }
            
            return cell
        }
        return UITableViewCell()

    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == items.count - 1 && !isLoading {
            currentPage += 1
            loadMoreData()
        }
    }
    
    func loadMoreData() {
        isLoading = true
        // Make a network request or fetch the next page of data
        // Append the new data to 'items'
        // Reload the table view with the updated data
        beaconsTableView.reloadData()
        sortTableView.reloadData()
        isLoading = false
    }

    
    
    
    
}
