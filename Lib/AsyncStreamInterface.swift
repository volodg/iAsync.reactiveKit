//
//  AsyncStreamInterface.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit_old//???

public protocol AsyncStreamInterface {

    associatedtype Value
    associatedtype Next
    associatedtype Error: ErrorType

    func asyncWithCallbacks(
        success _: Value -> Void,
        next     : Next  -> Void,
        error    : Error -> Void)

    func cancel()
}

@warn_unused_result
public func createStream<T: AsyncStreamInterface>(factory: () -> T) -> AsyncStream<T.Value, T.Next, T.Error> {

    return create(producer: { observer -> DisposableType? in

        var observerHolder: (AsyncEvent<T.Value, T.Next, T.Error> -> ())? = observer

        var objHolder: T? = nil

        let notifyOnce = { (event: AsyncEvent<T.Value, T.Next, T.Error>) -> () in
            guard let observer = observerHolder else { return }
            objHolder      = nil
            observerHolder = nil
            observer(event)
        }

        let obj = factory()
        objHolder = obj

        obj.asyncWithCallbacks(
            success: { notifyOnce(.Success($0))   },
            next   : { observerHolder?(.Next($0)) },
            error  : { notifyOnce(.Failure($0))   })

        return BlockDisposable {
            observerHolder = nil
            objHolder?.cancel()
            objHolder = nil
        }
    })
}
