
//
//  DNSSDInterfaceType+String.swift
//  Francis
//
//  Created by Andrew Shepard on 4/9/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation

//return ["Any", "Local Only", "Unicast", "P2P", "BLE"]

enum DNSSDInterfaceError: Error {
    case invalidString
}

extension DNSSDInterfaceType {
    public init?(string: String) {
        switch string {
        case "Any":
            self = DNSSDInterfaceType.any
        case "Local Only":
            self = DNSSDInterfaceType.localOnly
        case "Unicast":
            self = DNSSDInterfaceType.unicast
        case "P2P":
            self = DNSSDInterfaceType.P2P
        case "BLE":
            self = DNSSDInterfaceType.BLE
        default:
            return nil
        }
    }
}
