//
//  ObservableType+FilterNils.swift
//  Francis
//
//  Created by Andrew Shepard on 10/14/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

// https://gist.github.com/gravicle/8fd14b940e97e6d4bc7ecfec3703fd2e

import Foundation
import RxSwift

public protocol OptionalType {
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    public var value: Wrapped? {
        return self
    }
}

public extension ObservableType where E: OptionalType {
    
    /// Filter nil values from the Observable stream
    ///
    /// - Returns: A filtered stream with nil values removed
    public func filterNils() -> Observable<E.Wrapped> {
        return self.flatMap { element -> Observable<E.Wrapped> in
            guard let value = element.value else {
                return Observable<E.Wrapped>.empty()
            }
            return Observable<E.Wrapped>.just(value)
        }
    }
}

