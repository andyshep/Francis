//
//  ServiceViewModel.swift
//  Francis
//
//  Created by Andrew Shepard on 4/8/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

final class ServiceViewModel {
    
    var refreshEvent: AnyObserver<Void> {
        return _refreshEvent.asObserver()
    }
    private let _refreshEvent = PublishSubject<Void>()
    
    var entries: Observable<[String: String]> {
        return _entries.asObservable()
    }
    private let _entries = BehaviorRelay<[String: String]>(value: [:])
    
    var title: Observable<String> {
        return Observable.just(service.name)
    }
    
    private let service: NetService
    private let bag = DisposeBag()
    
    init(service: NetService) {
        
        self.service = service
        
        _refreshEvent
            .flatMapLatest { _ -> Observable<NetService> in
                let record = service.txtRecordData()
                if record?.count != 0 {
                    return Observable.just(service)
                } else {
                    return service.rx.resolve()
                }
            }
            .observeOn(MainScheduler.instance)
            .withLatestFrom(service.rx.address) { ($0, $1) }
            .map { (service, address) -> [String: Data] in
                guard let data = service.txtRecordData() else {
                    return [:]
                }
                var dictionary = NetService.dictionary(fromTXTRecord: data)
                
                if let address = address {
                    let data = address.data(using: .utf8)
                    dictionary["IP Address"] = data
                }
                return dictionary
            }
            .map { dictionary -> [String: String] in
                let result = dictionary.mapValues { (value) -> String in
                    return String(data: value, encoding: .utf8) ?? ""
                }
                
                return result
            }
            .bind(to: _entries)
            .disposed(by: bag)
    }
}
