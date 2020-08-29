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
        return browser.publisherForSearchTypes()
            .scan([NetService](), { (existing, updated) -> [NetService] in
                var services = existing
                services.append(contentsOf: updated)
                return services.unique.sorted(by: { $0.name < $1.name })
            })
            .eraseToAnyPublisher()
    }
    
    func publisherForServices(for serviceType: NetService) -> AnyPublisher<[NetService], Error> {
        return browser.publisherForServices(type: serviceType.query)
            .scan([NetService](), { (existing, updated) -> [NetService] in
                var services = existing
                services.append(contentsOf: updated)
                return services.unique.sorted(by: { $0.name < $1.name })
            })
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
            .map { (resolved, addresses) -> [Entry] in
                guard let data = service.txtRecordData() else { return [] }
                
                return NetService.dictionary(fromTXTRecord: data)
                    .mapValues { String(data: $0, encoding: .utf8) ?? "" }
                    .reduce(into: addresses) { (dictionary, keyvalue) in
                        dictionary[keyvalue.0] = keyvalue.1
                    }
                    .reduce(into: [Entry]()) { (accumulator, keyvalue) in
                        let entry = Entry(title: keyvalue.0, subtitle: keyvalue.1)
                        accumulator.append(entry)
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
