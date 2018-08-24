//
//  ServicesTypesViewModel.swift
//  Francis
//
//  Created by Andrew Shepard on 3/25/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

final class ServiceTypesViewModel {
    
    let refreshEvent = PublishSubject<DNSSDInterfaceType>()
    
    var serviceTypes: Observable<[DNSSDService]> {
        return servicesSubject.asObservable()
    }
    
    private let servicesSubject = BehaviorRelay<[DNSSDService]>(value: [])
    private let bag = DisposeBag()
    
    private var browser = ServiceBrowser()
    
    init(interface: DNSSDInterfaceType) {
        refreshEvent
            .asObservable()
            .subscribe(onNext: { [weak self] (interface) in
                self?.stopAndRefreshBrowsing(on: interface)
            })
            .disposed(by: bag)
        
        bindToServiceBrowser()
        
        browser.browseForType("_services._dns-sd._udp")
        browser.startBrowsing(on: interface)
    }
    
    deinit {
        browser.stopBrowsing()
    }
}

private extension ServiceTypesViewModel {
    private func bindToServiceBrowser() {
        browser.services
            .subscribe(onNext: { [weak self] (serviceNodes) in
                self?.servicesSubject.accept(serviceNodes)
            }, onError: { [weak self] (error) in
                self?.handleError(error)
            }, onCompleted: { [weak self] in
                self?.browser.stopBrowsing()
            })
            .disposed(by: bag)
    }
    
    private func handleError(_ error: Error) {
        print("\(#function): unhandled error: \(error)")
        browser.stopBrowsing()
    }
    
    private func stopAndRefreshBrowsing(on interface: DNSSDInterfaceType) {
        browser.stopBrowsing()
        servicesSubject.accept([])
        
        self.browser = ServiceBrowser()
        bindToServiceBrowser()
        
        browser.browseForType("_services._dns-sd._udp")
        browser.startBrowsing(on: interface)
    }
}
