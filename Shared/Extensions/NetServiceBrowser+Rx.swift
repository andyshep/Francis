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

extension Reactive where Base: NetServiceBrowser {
    
    private enum NetServiceBrowserRxError: Error {
        case signatureMismatch
    }
    
    /// 
    func searchForSearchTypes(domain: String = "local.") -> Observable<[NetService]> {
        return searchForServices(type: "_services._dns-sd._udp")
    }
    
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
            .share()
        
        base.stop()
        base.searchForServices(ofType: type, inDomain: domain)
        
        return result
    }
}
