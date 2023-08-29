//
//  OrderedMaterial.swift
//  MiniOrder
//
//  Created by Dylan Carlyle on 19/07/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation

struct ScannedBeacon: Codable, Hashable {
    var id: String
    var quantity: Int
    var index: Int
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
    
    static func == (lhs: ScannedBeacon, rhs: ScannedBeacon) -> Bool {
      lhs.id == rhs.id
    }
}


