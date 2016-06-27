//
//  AsyncStreamType+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 18/02/16.
//  Copyright © 2016 AppDaddy. All rights reserved.
//

import Foundation

import iAsync_utils

public extension AsyncStreamType where Error == ErrorWithContext {

    @warn_unused_result
    public func logError() -> AsyncStream<Value, Next, Error> {

        return self.on(failure: { $0.postToLog() })
    }
}

public extension AsyncStreamType {

    @warn_unused_result
    public func mapNext2AnyObject() -> AsyncStream<Value, AnyObject, Error> {

        return mapNext { _ in NSNull() as AnyObject }
    }
}
