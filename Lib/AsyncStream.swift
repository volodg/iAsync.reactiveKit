//
//  AsyncStream.swift
//  iAsync.reactiveKit
//
//  Created by Gorbenko Vladimir on 03/02/16.
//  Copyright © 2016 Volodymyr. All rights reserved.
//

import Foundation

import ReactiveKit

public struct AsyncStream<Event>: StreamType {

    public typealias Observer = Event -> ()

    public let producer: Observer -> DisposableType?

    public init(producer: Observer -> DisposableType?) {
        self.producer = producer
    }

    public func observe(on context: ExecutionContext?, observer: Observer) -> DisposableType {
        let serialDisposable = SerialDisposable(otherDisposable: nil)

        serialDisposable.otherDisposable = producer { event in
            if !serialDisposable.isDisposed {
                observer(event)
            }
        }
        return serialDisposable
    }
}

@warn_unused_result
public func createX<Event>(producer producer: (Event -> ()) -> DisposableType?) -> Stream<Event> {
    return Stream<Event>(producer: producer)
}
