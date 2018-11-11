//
//  NetService+Rx.swift
//  Francis
//
//  Created by Andrew Shepard on 10/27/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension Reactive where Base: NetService {
    
    private enum NetServiceRxError: Error {
        case signatureMismatch
    }
    
    /// Emits with the IP4 address associated with a `NetService`
    var address: Observable<String?> {
        return resolve().map { $0.addressIP4 }.share()
    }
    
    func resolve(withTimeout timeout: TimeInterval = 15.0) -> Observable<NetService> {
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
            .share()
        
        base.stop()
        base.resolve(withTimeout: timeout)
        
        return result
    }
}

private extension NetService {
    var addressIP4: String? {
        guard let data = addresses?.first else { return nil }
        return data.withUnsafeBytes { (addressPtr: UnsafePointer<sockaddr_in>) -> String? in
            if addressPtr.pointee.sin_family == __uint8_t(AF_INET) {
                guard
                    let bytes = inet_ntoa(addressPtr.pointee.sin_addr),
                    let ip = String(cString: bytes, encoding: .ascii)
                else { return nil }
                return ip
            }
            
            return nil
        }
    }
}
