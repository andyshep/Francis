//
//  NetServiceBrowser+Rx.swift
//  Francis
//
//  Created by Andrew Shepard on 10/27/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// Reactive wrapper for `NetServiceBrowser`
extension Reactive where Base: NetServiceBrowser {
    
    private enum NetServiceBrowserRxError: Error {
        case signatureMismatch
    }
    
    /// Searches for services operating under a `domain`.
    ///
    /// - Parameter domain: The domain to search for services in
    /// - Returns: An `Observable` collection of `NetService` found the `domain`
    func searchForSearchTypes(domain: String = "local.") -> Observable<[NetService]> {
        return searchForServices(type: "_services._dns-sd._udp")
    }
    
    /// Searches for services for a given `type` operating under a `domain`.
    ///
    /// - Parameters:
    ///   - type: The type of service to search for
    ///   - domain: The domain to search for services in
    /// - Returns: An `Observable` collection of `NetService` matching the `domain` and `type`
    func searchForServices(type: String, domain: String = "local.") -> Observable<[NetService]> {
        let selector = #selector(
            NetServiceBrowserDelegate
                .netServiceBrowser(_:didFind:moreComing:)
        )
        
        var services: [NetService] = []
        
        let result = RxNetServiceBrowserDelegateProxy
            .proxy(for: base)
            .methodInvoked(selector)
            .map { params -> [NetService] in
                guard
                    let service = params[1] as? NetService,
                    let moreComing = params[2] as? Bool
                else {
                    throw NetServiceBrowserRxError.signatureMismatch
                }
                
                services.append(service)
                
                return moreComing ? [] : services
            }
        
        base.stop()
        base.searchForServices(ofType: type, inDomain: domain)
        
        return result
    }
}
