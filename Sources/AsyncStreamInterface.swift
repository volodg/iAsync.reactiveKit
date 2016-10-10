//
//  AsyncStreamInterface.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import protocol ReactiveKit.Disposable
import class ReactiveKit.BlockDisposable

public protocol AsyncStreamInterface {

    associatedtype ValueT
    associatedtype NextT
    associatedtype ErrorT: Error

    func asyncWithCallbacks(
        success: @escaping (ValueT) -> Void,
        next   : @escaping (NextT)  -> Void,
        error  : @escaping (ErrorT) -> Void)

    func cancel()
}

public func createStreamWith<T: AsyncStreamInterface>(factory: @escaping () -> T) -> AsyncStream<T.ValueT, T.NextT, T.ErrorT> {

    return AsyncStream { observer -> Disposable in

        var observerHolder: ((AsyncEvent<T.ValueT, T.NextT, T.ErrorT>) -> ())? = observer

        var objHolder: T? = nil

        let notifyOnce = { (event: AsyncEvent<T.ValueT, T.NextT, T.ErrorT>) -> () in
            guard let observer = observerHolder else { return }
            objHolder      = nil
            observerHolder = nil
            observer(event)
        }

        let obj = factory()
        objHolder = obj

        obj.asyncWithCallbacks(
            success: { notifyOnce(.success($0))   },
            next   : { observerHolder?(.next($0)) },
            error  : { notifyOnce(.failure($0))   })

        return BlockDisposable {
            observerHolder = nil
            objHolder?.cancel()
            objHolder = nil
        }
    }
}
