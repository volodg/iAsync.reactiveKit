//
//  ActiveAsyncStream.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 07/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils

import ReactiveKit
import ReactiveKit_old//???

public final class ActiveAsyncStream<ValueT, NextT, ErrorT: ErrorType>: AsyncStreamType {

    public typealias Value = ValueT
    public typealias Next  = NextT
    public typealias Error = ErrorT

    public typealias Event = AsyncEvent<Value, Next, Error>

    private let stream: PushStream<Event>

    public typealias Observer = Event -> ()

    public init() {
        stream = PushStream()
    }

    public func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Observer) -> Disposable {

        return stream.observeNext { value in

            return observer(value)
        }
    }

    public func lift<R, P, E: ErrorType>(transform: Stream_old<AsyncEvent<Value, Next, Error>> -> Stream_old<AsyncEvent<R, P, E>>) -> AsyncStream<R, P, E> {
        return create { observer in

            let stream = self.stream.toStream().toStream()
            return transform(stream.map(id_)).observe(on: nil, observer: observer)
        }
    }

    public func next(event: Event) {
        stream.next(event)
    }

    internal func registerDisposable(disposable: Disposable) {
        stream.disposeBag.addDisposable(disposable)
    }
}

extension ActiveAsyncStream: BindableType_old {

    /// Creates a new observer that can be used to update the receiver.
    /// Optionally accepts a disposable that will be disposed on receiver's deinit.
    public func observer(disconnectDisposable: Disposable?) -> Event -> () {

        if let disconnectDisposable = disconnectDisposable {
            registerDisposable(disconnectDisposable)
        }

        return { [weak self] value in
            self?.next(value)
        }
    }
}
