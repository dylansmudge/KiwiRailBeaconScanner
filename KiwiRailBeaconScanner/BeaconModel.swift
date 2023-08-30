//
//  BeaconModel.swift
//  KRBeacon
//
//  Created by Dylan Carlyle on 30/08/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import Foundation

typealias BeaconModel = [BeaconModelItem]

struct BeaconModelItem: Decodable {
    let namespace: String?
    let instance: String?
    let voltage: Int32?
    let temp: Int32?
    let time: String?

    enum CodingKeys: String, CodingKey {
        case namespace
        case instance
        case voltage
        case temp
        case time
    }
}
