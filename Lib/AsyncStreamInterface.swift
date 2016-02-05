//
//  AsyncStreamInterface.swift
//  iAsync.reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit

public protocol AsyncStreamInterface {

    typealias Value
    typealias Next
    typealias Error: ErrorType

    func asyncWithCallbacks(
        success _: Value -> Void,
        next     : Next  -> Void,
        error    : Error -> Void)

    func cancel()
}

public struct streamBuilder<T: AsyncStreamInterface> {

    public typealias Factory = () -> T

    static public func createStream(factory: Factory) -> AsyncStream<T.Value, T.Next, T.Error> {

        return create(producer: { observer -> DisposableType? in

            let obj = factory()

            obj.asyncWithCallbacks(
                success: { observer(.Success($0)) },
                next   : { observer(.Next($0))    },
                error  : { observer(.Failure($0)) })

            return BlockDisposable { obj.cancel() }
        })
    }
}
