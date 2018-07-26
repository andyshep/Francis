//
//  ServicesViewModel.swift
//  Francis
//
//  Created by Andrew Shepard on 4/8/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

final class ServicesViewModel {
    
    let refreshEvent = PublishSubject<()>()
    
    var services: Observable<[DNSSDService]> {
        return servicesSubject.asObservable()
    }
    
    private let servicesSubject = BehaviorRelay<[DNSSDService]>(value: [])
    private let bag = DisposeBag()
    
    private let browser = ServiceBrowser()
    
    let service: DNSSDService
    let interface: DNSSDInterfaceType
    
    private var query: String {
        return "\(service.name).\(service.type)"
    }
    
    init(service: DNSSDService, interface: DNSSDInterfaceType) {
        self.service = service
        self.interface = interface
        
        browser.services
            .subscribe(onNext: { [weak self] (serviceNodes) in
                self?.servicesSubject.accept(serviceNodes)
            }, onError: { [weak self] (error) in
                self?.handleError(error)
            }, onCompleted: { [weak self] in
                self?.browser.stopBrowsing()
            })
            .disposed(by: bag)
        
        refreshEvent
            .subscribe(onNext: { [weak self] _ in
                self?.handleRefresh(on: interface)
            })
            .disposed(by: bag)
    }
    
    deinit {
        browser.stopBrowsing()
    }
}

private extension ServicesViewModel {
    private func handleRefresh(on interface: DNSSDInterfaceType) {
        browser.stopBrowsing()
        browser.browseForType(query)
        browser.startBrowsing(on: interface)
    }
    
    private func handleError(_ error: Error) {
        print("error: \(error)")
//        browser.stopBrowsing()
    }
}
