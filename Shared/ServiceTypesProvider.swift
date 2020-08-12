//
//  ServicesTypesProvider.swift
//  Francis
//
//  Created by Andrew Shepard on 3/25/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

final class ServiceTypesProvider {
    
    private let browser: NetServiceBrowser
    
    init(browser: NetServiceBrowser = NetServiceBrowser()) {
        self.browser = browser
    }
    
    deinit {
        browser.stop()
    }
}

extension ServiceTypesProvider {
    func publisherForServiceTypes() -> AnyPublisher<[NetService], Error> {
        var results: [NetService] = []
        
        return browser.publisherForSearchTypes()
            .map { services -> [NetService] in
                results.append(contentsOf: services)
                let sorted = results.unique.sorted(by: { $0.name < $1.name })
                return sorted
            }
            .eraseToAnyPublisher()
    }
    
    func publisherForServices(for serviceType: NetService) -> AnyPublisher<[NetService], Error> {
        var results: [NetService] = []
        
        return browser.publisherForServices(type: serviceType.query)
            .map { services -> [NetService] in
                results.append(contentsOf: services)
                let sorted = results.unique.sorted(by: { return $0.name > $1.name })
                return sorted
            }
            .eraseToAnyPublisher()
    }
    
    func publisherForServiceRecord(for service: NetService) -> AnyPublisher<[Entry], Error> {
        let servicePublisher = service.publisherForResolving()
            .eraseToAnyPublisher()
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
        
        return Publishers.CombineLatest(servicePublisher, addressesPublisher)
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
            .map { (dictionary) -> [Entry] in
                dictionary.reduce(into: [Entry]()) { (accumlator, input) in
                    let (key, value) = input
                    let entry = Entry(title: key, subtitle: value)
                    accumlator.append(entry)
                }
            }
            .eraseToAnyPublisher()
    }
}

private extension Array where Element: Hashable {
    var unique: [Element] {
        return Array(Set(self))
    }
}

private extension NetService {
    var query: String {
        guard let range = type.range(of: ".") else { return "" }
        
        let index = type.index(
            type.startIndex,
            offsetBy: range.lowerBound.utf16Offset(in: type)
        )
        let prefix = type[..<index]

        return "\(name).\(String(prefix))"
    }
}

struct Entry: Identifiable, Hashable {
    var id: UUID = UUID()
    
    let title: String
    let subtitle: String
}
