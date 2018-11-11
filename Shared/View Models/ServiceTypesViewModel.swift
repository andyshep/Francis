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
    
    var refreshEvent: AnyObserver<Void> {
        return _refreshEvent.asObserver()
    }
    private let _refreshEvent = PublishSubject<Void>()
    
    var serviceTypes: Observable<[NetService]> {
        return _services.asObservable()
    }
    private let _services = BehaviorRelay<[NetService]>(value: [])
    
    private var browser = NetServiceBrowser()
    private var browserBag = DisposeBag()
    
    private var bag = DisposeBag()
    
    init() {
        _refreshEvent
            .asObservable()
            .subscribe(onNext: { [weak self] in
                self?.stopAndRefreshBrowsing()
            })
            .disposed(by: bag)
        
        bind(to: browser)
    }
    
    deinit {
        browser.stop()
    }
    
    private func stopAndRefreshBrowsing() {
        browser.stop()
        browserBag = DisposeBag()
        
        browser = NetServiceBrowser()
        _services.accept([])
        
        bind(to: browser)
    }
    
    private func bind(to browser: NetServiceBrowser) {
        browser.rx.searchForSearchTypes()
            .observeOn(MainScheduler.instance)
            .bind(to: _services)
            .disposed(by: browserBag)
    }
}
