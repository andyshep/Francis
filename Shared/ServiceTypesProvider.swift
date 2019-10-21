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
    
    /// To be triggered when the view model should be refreshed. The service
    /// browser will stop and restart, and the list of services types will refresh.
    var refreshEvent: AnySubscriber<Void, Never> {
        return AnySubscriber(_refreshEvent)
    }
    private let _refreshEvent = PassthroughSubject<Void, Never>()
    
    /// Emits with the list of service types for browsing.
    var serviceTypes: AnyPublisher<[NetService], Never> {
        return _services.eraseToAnyPublisher()
    }
    private let _services = CurrentValueSubject<[NetService], Never>.init([])
    
    private var browser = NetServiceBrowser()
    private var browserSubscription: AnyCancellable?
    
    private var cancelables: [AnyCancellable] = []
    
    init() {
        _refreshEvent
            .sink { [weak self] _ in
                self?.stopAndRefreshBrowsing()
            }
            .store(in: &cancelables)
        
        bind(to: browser)
    }
    
    deinit {
        browser.stop()
        cancelables.forEach { $0.cancel() }
    }
    
    private func stopAndRefreshBrowsing() {
        browser.stop()
        browserSubscription?.cancel()
        
        browser = NetServiceBrowser()
        _services.send([])
        
        bind(to: browser)
    }
    
    private func bind(to browser: NetServiceBrowser) {
        browserSubscription = browser
            .publisherForSearchTypes()
            .sink { [weak self] (result) in
                guard let this = self else { return }
                
                switch result {
                case .success(let services):
                    var contents = this._services.value
                    contents.append(contentsOf: services)
                    let ordered = contents.sorted(by: { $0.name < $1.name })
                    this._services.send(ordered)
                case .failure(let error):
                    print("unhandled error: \(error)")
                }
            }
    }
}
