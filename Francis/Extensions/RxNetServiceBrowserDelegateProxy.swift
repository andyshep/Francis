//
//  RxNetServiceBrowserDelegateProxy.swift
//  Francis
//
//  Created by Andrew Shepard on 10/27/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import AppKit
import RxSwift
import RxCocoa

extension NetServiceBrowser: HasDelegate {
    public typealias Delegate = NetServiceBrowserDelegate
}

public final class RxNetServiceBrowserDelegateProxy
    : DelegateProxy<NetServiceBrowser, NetServiceBrowserDelegate>
    , DelegateProxyType
    , NetServiceBrowserDelegate {
    
    private let bag = DisposeBag()
    
    private init(parent: NetServiceBrowser) {
        super.init(parentObject: parent, delegateProxy: RxNetServiceBrowserDelegateProxy.self)
        parent.delegate = self
    }
    
    // MARK: <DelegateProxyType>
    
    public static func registerKnownImplementations() {
        self.register { (parent) -> RxNetServiceBrowserDelegateProxy in
            return RxNetServiceBrowserDelegateProxy(parent: parent)
        }
    }
}
