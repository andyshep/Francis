//
//  ServicesProvider.swift
//  Francis
//
//  Created by Andrew Shepard on 4/8/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

final class ServicesProvider {
    
    /// To be triggered when the view model should be refreshed. The service
    /// browser will stop and restart, and the list of services types will refresh.
    let refreshEvent = PassthroughSubject<Void, Never>()
    
    /// Emits with the list of services for browsing.
    var services: AnyPublisher<[NetService], Never> {
        return _services.eraseToAnyPublisher()
    }
    private let _services = CurrentValueSubject<[NetService], Never>.init([])
    
    /// Emits with the title of the top level service.
    var title: AnyPublisher<String, Never> {
        return _title.eraseToAnyPublisher()
    }
    private let _title = CurrentValueSubject<String, Never>.init("")
    
    private var cancellables: [AnyCancellable] = []
    private let browser = NetServiceBrowser()
    
    init(service: NetService) {
        _title.send(service.name)
        
        refreshEvent
            .do(onNext: { [unowned self] in
                self._services.send([])
            })
            .map { _ -> String in
                let type = service.type
                guard let range = type.range(of: ".") else { return "" }
                
                let index = type.index(
                    type.startIndex,
                    offsetBy: range.lowerBound.utf16Offset(in: type)
                )
                let prefix = type[..<index]

                return "\(service.name).\(String(prefix))"
            }
            .flatMapLatest { [unowned self] query -> NetServiceBrowserPublisher in
                return self.browser.publisherForServices(type: query)
            }
            .sink { [weak self] (result) in
                guard let this = self else { return }
                
                switch result {
                case .success(let services):
                    var contents = this._services.value
                    contents.append(contentsOf: services)
                    let sorted = contents.sorted(by: { return $0.name > $1.name })
                    this._services.send(sorted)
                case .failure(let error):
                    print("unhandled error: \(error)")
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        browser.stop()
        cancellables.forEach { $0.cancel() }
    }
}
