//
//  NetService+Combine.swift
//  Francis
//
//  Created by Andrew Shepard on 8/26/19.
//  Copyright © 2019 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

enum NetServicePublisherError: Error {
    case cannotResolveService
    case error(userInfo:  [String : NSNumber])
}

final class NetServiceSubscription<SubscriberType: Subscriber>: NSObject, Subscription, NetServiceDelegate where SubscriberType.Input == NetService {
    
    private var subscriber: SubscriberType?
    private let service: NetService
    
    init(subscriber: SubscriberType, service: NetService) {
        self.subscriber = subscriber
        self.service = service
        
        super.init()
        
        service.delegate = self
    }
    
    func request(_ demand: Subscribers.Demand) {
        service.stop()
        service.resolve(withTimeout: 15.0)
    }
    
    func cancel() {
        subscriber = nil
    }
    
    // MARK: <NetServiceDelegate>
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        _ = subscriber?.receive(service)
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        // TODO: send error thru subscriber
    }
}

struct NetServicePublisher: Publisher {
    typealias Output = NetService
    typealias Failure = Error
    
    private let service: NetService
    
    init(service: NetService) {
        self.service = service
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, NetServicePublisher.Failure == S.Failure, NetServicePublisher.Output == S.Input {
        let subscription = NetServiceSubscription(
            subscriber: subscriber,
            service: service
        )
        subscriber.receive(subscription: subscription)
    }
}

extension NetService {
    
    func publisherForResolving() -> NetServicePublisher {
        return NetServicePublisher(service: self)
    }
    
    /// The IPv4 address belonging to a service
    var addressIPv4: String? {
        return addresses?.compactMap { (data) -> String? in
            data.withUnsafeBytes({ (ptr) -> String? in
                guard
                    let sockaddr_in = ptr.bindMemory(to: sockaddr_in.self).baseAddress,
                    sockaddr_in.pointee.sin_family == __uint8_t(AF_INET),
                    let bytes = inet_ntoa(sockaddr_in.pointee.sin_addr),
                    let address = String(cString: bytes, encoding: .ascii)
                else { return nil }
                return address
            })
        }.first
    }

    /// The IPv6 address belonging to a service
    var addressIPv6: String? {
        return addresses?.compactMap { (data) -> String? in
            return data.withUnsafeBytes { (ptr) -> String? in
                guard
                    let addressPtr = ptr.bindMemory(to: sockaddr_in6.self).baseAddress,
                    addressPtr.pointee.sin6_family == __uint8_t(AF_INET6)
                else { return nil }
                
                return data.withUnsafeBytes { (ptr) -> String? in
                    guard
                        let sockaddr_in6 = ptr.bindMemory(to: sockaddr_in6.self).baseAddress
                        else { return nil }
                    
                    var sin6AddressPtr = sockaddr_in6.pointee.sin6_addr
                    
                    let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
                    defer { buffer.deallocate() }
                    
                    guard
                        let bytes = inet_ntop(
                            Int32(sockaddr_in6.pointee.sin6_family),
                            &sin6AddressPtr,
                            buffer,
                            __uint32_t(INET6_ADDRSTRLEN)
                        ),
                        let address = String(cString: bytes, encoding: .ascii)
                        else { return nil }
                    return address
                }
            }
        }.first
    }
}

// MARK: <Identifiable>

extension NetService: Identifiable { }
