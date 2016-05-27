//
//  StreamOwner.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright © 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_utils

import ReactiveKit

final public class StreamOwner<Value, Next, Error: ErrorType> {

    let barrier: Bool

    var stream: AsyncStream<Value, Next, Error>!

    private var disposeStream: SerialDisposable? = nil
    var observer: ObserverType?

    typealias ObserverType = AsyncEvent<Value, Next, Error> -> Void
    typealias OnComplete   = StreamOwner<Value, Next, Error> -> Void
    private let onComplete: OnComplete

    init<T: AsyncStreamType where T.Value == Value, T.Next == Next, T.Error == Error>(stream: T, observer: ObserverType, barrier: Bool, onComplete: OnComplete) {

        self.stream     = stream.map(id_)
        self.observer   = observer
        self.barrier    = barrier
        self.onComplete = onComplete
    }

    func performStream() {

        self.disposeStream = SerialDisposable(otherDisposable: nil)

        let observer = self.observer!
        let dispose = stream.on(completed: { [weak self] in self?.complete() }).observe(observer: observer)

        if let dispose_ = self.disposeStream {
            dispose_.otherDisposable = dispose
        }
    }

    func dispose() {

        disposeStream?.dispose()
        complete()
    }

    private func complete() {

        onComplete(self)
        stream = nil
        disposeStream = nil
    }
}
