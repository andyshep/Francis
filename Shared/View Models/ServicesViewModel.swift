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
    
    var refreshEvent: AnyObserver<Void> {
        return _refreshEvent.asObserver()
    }
    private let _refreshEvent = PublishSubject<Void>()
    
    var services: Observable<[NetService]> {
        return _services.asObservable()
    }
    private let _services = BehaviorRelay<[NetService]>(value: [])
    
    var title: Observable<String> {
        return _title.asObservable()
    }
    private let _title: BehaviorRelay<String>
    
    public let bag = DisposeBag()
    private let browser = NetServiceBrowser()
    
    init(service: NetService) {
        _title = BehaviorRelay<String>(value: service.name)
        
        _refreshEvent
            .flatMapLatest { Observable.just(service) }
            .map { service -> String in
                let type = service.type
                let range = type.range(of: ".")!
                let index = type.index(
                    type.startIndex,
                    offsetBy: range.lowerBound.utf16Offset(in: type)
                )
                let prefix = type[..<index]
                
                return "\(service.name).\(String(prefix))"
            }
            .flatMapLatest { [weak self] (query) -> Observable<[NetService]> in
                guard let this = self else { return Observable.never() }
                return this.browser.rx.searchForServices(type: query)
            }
            .distinctUntilChanged()
            .map { (services) -> [NetService] in
                return services.sorted(by: { return $0.name > $1.name })
            }
            .bind(to: _services)
            .disposed(by: bag)
    }

    deinit {
        browser.stop()
    }
}
