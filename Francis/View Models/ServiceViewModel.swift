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
    
    var entries: Observable<[String: String]> {
        return _entries
    }
    private let _entries = PublishSubject<[String: String]>()
    
    private let bag = DisposeBag()
    
    init(service: NetService) {
        service.rx
            .resolve(withTimeout: 60.0)
            .map { (service) -> [String: Data] in
                guard let data = service.txtRecordData() else { return [:] }
                let dictionary = NetService.dictionary(fromTXTRecord: data)
                
                return dictionary
            }
            .map { dictionary -> [String: String] in
                return dictionary.mapValues { (value) -> String in
                    return String(data: value, encoding: .utf8) ?? ""
                }
            }
            .bind(to: _entries)
            .disposed(by: bag)
    }
}
