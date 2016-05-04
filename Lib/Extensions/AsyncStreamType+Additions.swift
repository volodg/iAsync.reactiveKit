//
//  AsyncStreamType+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 18/02/16.
//  Copyright (c) 2016 AppDaddy. All rights reserved.
//

import Foundation

public extension AsyncStreamType where Error == ErrorWithContext {

    public func logError() -> AsyncStream<Value, Next, Error> {

        return self.on(failure: { $0.error.writeErrorWithLogger($0.context) })
    }
}

public extension AsyncStreamType {

    public func mapNext2AnyObject() -> AsyncStream<Value, AnyObject, Error> {

        return mapNext { _ in NSNull() as AnyObject }
    }
}
