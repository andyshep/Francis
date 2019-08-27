//
//  NSViewController+Combine.swift
//  Francis
//
//  Created by Andrew Shepard on 8/26/19.
//  Copyright © 2019 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

extension NSViewController {
    var representedObjectPublisher: AnyPublisher<Any?, Never> {
        return KeyValueObservingPublisher(
            object: self,
            keyPath: \.representedObject,
            options: []
        )
        .eraseToAnyPublisher()
    }
}
