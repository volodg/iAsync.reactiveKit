//
//  StreamType+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 09/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit

extension StreamType {
    @warn_unused_result
    public func next<S : StreamType>(transform: Self.Event -> S) -> Stream<S.Event> {
        return next(transform)
    }
}
