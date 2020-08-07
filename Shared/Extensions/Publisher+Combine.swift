//
//  File.swift
//  Francis
//
//  Created by Andrew Shepard on 8/26/19.
//  Copyright © 2019 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

extension Publisher {
    func flatMapLatest<T: Publisher>(_ transform: @escaping (Self.Output) -> T) -> Publishers.SwitchToLatest<T, Publishers.Map<Self, T>> where T.Failure == Self.Failure {
        map(transform).switchToLatest()
    }
}

extension Publisher {
    func `do`(onNext next: @escaping () -> ()) -> Publishers.HandleEvents<Self> {
        return handleEvents(receiveOutput: { _ in
            next()
        })
    }
    
    func `do`(onNext next: @escaping (Output) -> ()) -> Publishers.HandleEvents<Self> {
        return handleEvents(receiveOutput: { output in
            next(output)
        })
    }
    
    func toVoid() -> Publishers.Map<Self, Void> {
        return map { _ in () }
    }
}
