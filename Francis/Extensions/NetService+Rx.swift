//
//  NetService+Rx.swift
//  Francis
//
//  Created by Andrew Shepard on 10/27/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import AppKit
import RxCocoa
import RxSwift

extension Reactive where Base: NetService {
    
    private enum NetServiceRxError: Error {
        case signatureMismatch
    }
    
//    var address: Observable<String> {
//        return base.addresses.
//    }
    
    func resolve(withTimeout timeout: TimeInterval = 60.0) -> Observable<NetService> {
        let selector = #selector(
            NetServiceDelegate
                .netServiceDidResolveAddress(_:)
            )
        
        let result = RxNetServiceDelegateProxy.proxy(for: base)
            .methodInvoked(selector)
            .map { params -> NetService in
                guard let service = params[0] as? NetService else {
                    throw NetServiceRxError.signatureMismatch
                }
                
                return service
            }
        
        self.base.resolve(withTimeout: timeout)
        
        return result
    }
}
