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
    
    private let service: NetService
    private var cancelables: [AnyCancellable] = []
    
    init(service: NetService) {
        self.service = service
        
        _title.send(service.name)
        
        let servicePublisher = service.publisherForResolving()
            .share()

        let addressesPublisher = servicePublisher
            .map { service -> [String: String] in
                var result: [String: String] = [:]
                result["IPv4"] = service.addressIPv4
                result["IPv6"] = service.addressIPv6

                return result
            }
            .share()
            .eraseToAnyPublisher()
        
        refreshEvent
            .mapError { _ -> Error in }
            .flatMapLatest {  _ in Publishers.CombineLatest(servicePublisher, addressesPublisher) }
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
