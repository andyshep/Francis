//
//  ServiceProvider.swift
//  Francis
//
//  Created by Andrew Shepard on 4/8/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

final class ServiceProvider {
    
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
    
    private var addresses: AnyPublisher<[String: String], Error> {
//        return Publishers.CombineLatest(
//            service.ipv4AddressPublisher(),
//            service.ipv6AddressPublisher()
//        )
        return Just(())
        .mapError { _ -> Error in }
        .map { _ -> [String: String] in
//            var result: [String: String] = [:]
//
//            if let addressIPv4 = addressIPv4 {
//                result["IPv4"] = addressIPv4
//            }
//            if let addressIPv6 = addressIPv6 {
//                result["IPv6"] = addressIPv6
//            }
//
//            return result
            return [:]
        }
        .eraseToAnyPublisher()
    }
    
    private let service: NetService
    private var cancelables: [AnyCancellable] = []
    
    init(service: NetService) {
        self.service = service
        
        _title.send(service.name)
        
        refreshEvent
            .mapError { _ -> Error in }
            .flatMap { _ in Publishers.CombineLatest(service.publisherForResolving(), self.addresses) }
            .map { (resolved, addresses) -> ((NetService, [String: Data]), [String: String]) in
                guard let data = service.txtRecordData() else { return ((resolved, [:]), addresses) }
                return ((service, NetService.dictionary(fromTXTRecord: data)), addresses)
            }
            .map { (result) -> [String: String] in
                let ((_, dataDictionary), addresses) = result
                var dictionary = dataDictionary.mapValues { (value) -> String in
                    return String(data: value, encoding: .utf8) ?? ""
                }
                
                addresses.forEach { (key, value) in
                    dictionary[key] = value
                }
                
                return dictionary
            }
            .removeDuplicates()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] (data) in
                    self?._entries.send(data)
                }
            )
            .store(in: &cancelables)
    }
}
