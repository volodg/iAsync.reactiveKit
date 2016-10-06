//
//  AsyncStreamType+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 18/02/16.
//  Copyright © 2016 AppDaddy. All rights reserved.
//

import Foundation

import iAsync_utils

public extension AsyncStreamType where ErrorT == ErrorWithContext {

    public func logError() -> AsyncStream<ValueT, NextT, ErrorT> {

        return self.on(failure: { $0.postToLog() })
    }
}

public extension AsyncStreamType {

    public func mapNext2AnyObject() -> AsyncStream<ValueT, AnyObject, ErrorT> {

        return mapNext { _ in NSNull() as AnyObject }
    }
}
