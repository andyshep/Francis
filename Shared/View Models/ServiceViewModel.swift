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
        return _title.asObservable()
    }
    private let _title = BehaviorRelay<String>(value: "")
    
    private let bag = DisposeBag()
    
    init(service: NetService) {
        
        _title.accept(service.name)
        
        let addresses = Observable
            .zip(service.rx.addressIPv4, service.rx.addressIPv6) { ($0, $1) }
            .map { (addressIPv4, addressIPv6) -> [String: String] in
                var result: [String: String] = [:]
                
                if let addressIPv4 = addressIPv4 {
                    result["IPv4"] = addressIPv4
                }
                if let addressIPv6 = addressIPv6 {
                    result["IPv6"] = addressIPv6
                }
                
                return result
        }
        
        _refreshEvent
            .flatMapLatest { _ -> Observable<NetService> in
                return service.rx.resolve()
            }
            .observeOn(MainScheduler.instance)
            .map { (service) -> [String: Data] in
                guard let data = service.txtRecordData() else { return [:] }
                return NetService.dictionary(fromTXTRecord: data)
            }
            .withLatestFrom(addresses) { ($0, $1) }
            .map { (dataDictionary, addresses) -> [String: String] in
                var dictionary = dataDictionary.mapValues { (value) -> String in
                    return String(data: value, encoding: .utf8) ?? ""
                }
                
                addresses.forEach { (key, value) in
                    dictionary[key] = value
                }
                
                return dictionary
            }
            .distinctUntilChanged()
            .bind(to: _entries)
            .disposed(by: bag)
    }
}
