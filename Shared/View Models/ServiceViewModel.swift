//
//  ServiceViewModel.swift
//  Francis
//
//  Created by Andrew Shepard on 4/8/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

final class ServiceViewModel {
    
    /// To be triggered when the view model should be refreshed. A new
    /// text record will be fetched from the service and emit through the
    /// `entries` observable.
//    var refreshEvent: AnySubscriber<Void, Never> {
//        return AnySubscriber(_refreshEvent)
//    }
    let refreshEvent = PassthroughSubject<Void, Never>()
    
    /// Emits whenever the service attributes change.
    var entries: AnyPublisher<[String: String], Never> {
        return _entries.eraseToAnyPublisher()
    }
    private let _entries = CurrentValueSubject<[String: String], Never>([:])
    
    /// Emits with the title of the service
    var title: AnyPublisher<String, Never> {
        return _title.eraseToAnyPublisher()
    }
    private let _title = CurrentValueSubject<String, Never>("")
    
    private var cancelables: [AnyCancellable] = []
    
    init(service: NetService) {
        
        _title.send(service.name)
        
        let addresses = Publishers.Zip(
            service.ipv4AddressPublisher(),
            service.ipv6AddressPublisher()
        )
        .map { (addressIPv4, addressIPv6) -> [String: String] in
            var result: [String: String] = [:]
            
            if let addressIPv4 = addressIPv4 {
                result["IPv4"] = addressIPv4
            }
            if let addressIPv6 = addressIPv6 {
                result["IPv6"] = addressIPv6
            }
            
            return result
        }
        .eraseToAnyPublisher()
        
//        refreshEvent
//            .flatMap { _ -> NetServicePublisher in
//                return service.publisherForResolving()
//            }
//            .receive(on: RunLoop.main)
            
        
//        _refreshEvent
//            .flatMapLatest { _ -> Observable<NetService> in
//                return service.rx.resolve()
//            }
//            .observeOn(MainScheduler.instance)
//            .map { (service) -> [String: Data] in
//                guard let data = service.txtRecordData() else { return [:] }
//                return NetService.dictionary(fromTXTRecord: data)
//            }
//            .withLatestFrom(addresses) { ($0, $1) }
//            .map { (dataDictionary, addresses) -> [String: String] in
//                var dictionary = dataDictionary.mapValues { (value) -> String in
//                    return String(data: value, encoding: .utf8) ?? ""
//                }
//                
//                addresses.forEach { (key, value) in
//                    dictionary[key] = value
//                }
//                
//                return dictionary
//            }
//            .distinctUntilChanged()
//            .bind(to: _entries)
//            .disposed(by: bag)
    }
}
