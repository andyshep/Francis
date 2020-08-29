//
//  AppEnvironment.swift
//  Francis
//
//  Created by Andrew Shepard on 8/9/20.
//

import Foundation

struct AppEnvironment {
    let serviceTypesProvider: ServiceTypesProvider
    
    init(serviceTypesProvider: ServiceTypesProvider = ServiceTypesProvider()) {
        self.serviceTypesProvider = serviceTypesProvider
    }
}
