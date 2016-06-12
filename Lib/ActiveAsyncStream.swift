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

public final class ActiveAsyncStream<ValueT, NextT, ErrorT: ErrorType>: AsyncStreamType {

    public typealias Value = ValueT
    public typealias Next  = NextT
    public typealias Error = ErrorT

    public typealias Event = AsyncEvent<Value, Next, Error>

    private let stream: ActiveStream<Event>

    public typealias Observer = Event -> ()

    public init() {
        stream = ActiveStream()
    }

    public init(producer: Observer -> DisposableType?) {
        stream = ActiveStream  { observer in
            var observerHolder: Observer? = observer

            let dispose = producer { event in
                if let observer = observerHolder {
                    if event.isTerminal {
                        observerHolder = nil
                    }
                    observer(event)
                }
            }

            return BlockDisposable { _ in
                //observerHolder = nil
                dispose?.dispose()
            }
        }
    }

    public func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Observer) -> DisposableType {
        return stream.observe(on: context, observer: observer)
    }

    @warn_unused_result
    public func lift<R, P, E: ErrorType>(transform: Stream<AsyncEvent<Value, Next, Error>> -> Stream<AsyncEvent<R, P, E>>) -> AsyncStream<R, P, E> {
        return create { observer in
            return transform(self.stream.map(id_)).observe(on: nil, observer: observer)
        }
    }

    public func next(event: Event) {
        stream.next(event)
    }

    internal func registerDisposable(disposable: DisposableType) {
        stream.registerDisposable(disposable)
    }
}

public func create<Value, Next, Error: ErrorType>(producer producer: (AsyncEvent<Value, Next, Error> -> ()) -> DisposableType?) -> ActiveAsyncStream<Value, Next, Error> {
    return ActiveAsyncStream<Value, Next, Error> { observer in
        return producer(observer)
    }
}

extension ActiveAsyncStream: BindableType {

    /// Creates a new observer that can be used to update the receiver.
    /// Optionally accepts a disposable that will be disposed on receiver's deinit.
    public func observer(disconnectDisposable: DisposableType?) -> Event -> () {

        if let disconnectDisposable = disconnectDisposable {
            registerDisposable(disconnectDisposable)
        }

        return { [weak self] value in
            self?.next(value)
        }
    }
}
