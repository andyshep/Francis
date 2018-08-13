//
//  ServiceBrowser.swift
//  Francis
//
//  Created by Andrew Shepard on 3/24/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import RxSwift

enum ServiceBrowserError: Error {
    case couldNotResolve(Error)
    case unknown
}

final class ServiceBrowser: NSObject {
    private var browser: DNSSDBrowser!
    
    var services: Observable<[DNSSDService]> {
        return servicesSubject.asObservable()
    }
    
    private var servicesSubject = PublishSubject<[DNSSDService]>()
    private var _services: [DNSSDService] = []
    
    func browseForType(_ type: String, domain: String = "local") {
        stopBrowsing()
        _services = []
        servicesSubject.onNext(_services)
        
        self.browser = DNSSDBrowser(domain: domain, type: type)
        browser.delegate = self
    }
    
    func startBrowsing(on interface: DNSSDInterfaceType) {
        servicesSubject.onNext([])
        browser.startBrowse(on: interface)
    }
    
    func stopBrowsing() {
        guard browser != nil else { return }
        browser.stop()
    }
}

extension ServiceBrowser: DNSSDBrowserDelegate {
    func dnssdBrowserWillBrowse(_ browser: DNSSDBrowser) {
        // implement if necessary
    }
    
    func dnssdBrowser(_ browser: DNSSDBrowser, didAdd service: DNSSDService, moreComing: Bool) {
        guard !_services.contains(service) else { return }
        
        _services.append(service)
        servicesSubject.onNext(_services)
    }
    
    func dnssdBrowser(_ browser: DNSSDBrowser, didNotBrowse error: Error?) {
        guard let error = error else {
            return print("\(#function) unhandled error")
        }
        
        servicesSubject.onError(error)
    }
}

fileprivate func qualifiedServiceType(from service: NetService) -> String {
    let name = service.name
    let type = service.type
    
    let start = type.startIndex
    let end = type.index(start, offsetBy: 4)
    let transport = String(type[start..<end])
    
    return name + "." + transport
}
