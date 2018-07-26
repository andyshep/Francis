//
//  ServiceViewModel.swift
//  Francis
//
//  Created by Andrew Shepard on 4/8/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

final class ServiceViewModel {
    
    let service: DNSSDService
    let interface: DNSSDInterfaceType
    
    init(service: DNSSDService, interface: DNSSDInterfaceType) {
        self.service = service
        self.interface = interface
    }
}

