//
//  RxNetServiceDelegateProxy.swift
//  Francis
//
//  Created by Andrew Shepard on 10/27/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import AppKit
import RxSwift
import RxCocoa

extension NetService: HasDelegate {
    public typealias Delegate = NetServiceDelegate
}

public final class RxNetServiceDelegateProxy
    : DelegateProxy<NetService, NetServiceDelegate>
    , DelegateProxyType
    , NetServiceDelegate {
    
    private let bag = DisposeBag()
    
    private init(parent: NetService) {
        super.init(parentObject: parent, delegateProxy: RxNetServiceDelegateProxy.self)
        parent.delegate = self
    }
    
    // MARK: <DelegateProxyType>
    
    public static func registerKnownImplementations() {
        self.register { (parent) -> RxNetServiceDelegateProxy in
            return RxNetServiceDelegateProxy(parent: parent)
        }
    }
}

