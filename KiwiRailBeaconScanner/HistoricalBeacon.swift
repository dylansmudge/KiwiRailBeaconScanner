//
//  Material.swift
//  MiniOrder
//
//  Created by Dylan Carlyle on 11/07/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation

struct HistoricalBeacon: Codable, Hashable {
    var id: Int
    var imageName: String
    var displayName: String
    var date: String
    var voltage: String
    
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
    
    static func == (lhs: HistoricalBeacon, rhs: HistoricalBeacon) -> Bool {
      lhs.id == rhs.id
    }
    
}

struct HistoricalBeacons: Codable {
    let historicalBeacons: [HistoricalBeacon]
}

