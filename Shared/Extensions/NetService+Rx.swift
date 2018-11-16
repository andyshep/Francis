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

/// Reactive wrapper for `NetService`
extension Reactive where Base: NetService {
    
    private enum NetServiceRxError: Error {
        case signatureMismatch
    }
    
    /// Emits with the IPv4 address associated with a `NetService`
    var addressIPv4: Observable<String?> {
        return resolve().map { $0.addressIPv4 }.share()
    }
    
    /// Emits with the IPv4 address associated with a `NetService`
    var addressIPv6: Observable<String?> {
        return resolve().map { $0.addressIPv6 }.share()
    }
    
    /// Resolve a service within a given `timeout`.
    ///
    /// - Parameter timeout: A duration to wait before the resolve times out.
    /// - Returns: An `Observable` with the `NetService` after resolution.
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
        
        base.stop()
        base.resolve(withTimeout: timeout)
        
        return result
    }
}

private extension NetService {
    
    /// The IPv4 address belonging to a service
    var addressIPv4: String? {
        return addresses?.compactMap { (data) -> String? in
            return data.withUnsafeBytes { (addressPtr: UnsafePointer<sockaddr_in>) -> String? in
                guard
                    addressPtr.pointee.sin_family == __uint8_t(AF_INET),
                    let bytes = inet_ntoa(addressPtr.pointee.sin_addr),
                    let address = String(cString: bytes, encoding: .ascii)
                else { return nil }
                return address
            }
        }.first
    }

    /// The IPv6 address belonging to a service
    var addressIPv6: String? {
        return addresses?.compactMap { (data) -> String? in
            return data.withUnsafeBytes { (addressPtr: UnsafePointer<sockaddr_in>) -> String? in
                guard
                    addressPtr.pointee.sin_family == __uint8_t(AF_INET6)
                else { return nil }
                
                return data.withUnsafeBytes { (address6Ptr: UnsafePointer<sockaddr_in6>) -> String? in
                    let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
                    var sin6AddressPtr = address6Ptr.pointee.sin6_addr
                    
                    guard
                        let bytes = inet_ntop(Int32(address6Ptr.pointee.sin6_family),
                                              &sin6AddressPtr,
                                              buffer,
                                              __uint32_t(INET6_ADDRSTRLEN)),
                        let address = String(cString: bytes, encoding: .ascii)
                    else { return nil }
                    return address
                }
            }
        } .first
    }
}
