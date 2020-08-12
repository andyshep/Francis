//
//  NetServiceBrowser+Combine.swift
//  Francis
//
//  Created by Andrew Shepard on 6/28/19.
//  Copyright © 2019 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

enum BrowserError: Error {
    case searchFailed(info: [String: NSNumber])
}

final class NetServiceBrowserSubscription<SubscriberType: Subscriber>: NSObject, Subscription, NetServiceBrowserDelegate where SubscriberType.Input == [NetService], SubscriberType.Failure == Error {
    
    private var subscriber: SubscriberType?
    private let browser: NetServiceBrowser
    private let type: String
    private let domain: String
    
    init(subscriber: SubscriberType, browser: NetServiceBrowser, type: String, domain: String) {
        self.subscriber = subscriber
        self.browser = browser
        self.type = type
        self.domain = domain
        
        super.init()
        
        browser.delegate = self
    }
    
    func request(_ demand: Subscribers.Demand) {
        browser.stop()
        browser.searchForServices(ofType: type, inDomain: domain)
    }
    
    func cancel() {
        subscriber = nil
    }
    
    // MARK: <NetServiceBrowserDelegate>
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        _ = subscriber?.receive([service])
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        _ = subscriber?.receive(completion: .failure(BrowserError.searchFailed(info: errorDict)))
    }
}

struct NetServiceBrowserPublisher: Publisher {
    typealias Output = [NetService]
    typealias Failure = Error
    
    private let type: String
    private let domain: String
    private let browser: NetServiceBrowser
    
    init(type: String,
         domain: String,
         browser: NetServiceBrowser) {
        self.type = type
        self.domain = domain
        self.browser = browser
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, NetServiceBrowserPublisher.Failure == S.Failure, NetServiceBrowserPublisher.Output == S.Input {
        let subscription = NetServiceBrowserSubscription(
            subscriber: subscriber,
            browser: browser,
            type: type,
            domain: domain
        )
        subscriber.receive(subscription: subscription)
    }
}

extension NetServiceBrowser {
    func publisherForServices(type: String, domain: String = "local.") -> NetServiceBrowserPublisher {
        return NetServiceBrowserPublisher(type: type, domain: domain, browser: self)
    }
    
    func publisherForSearchTypes(domain: String = "local.") -> NetServiceBrowserPublisher {
        return publisherForServices(type: "_services._dns-sd._udp")
    }
}
