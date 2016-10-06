//
//  StreamOwner.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright © 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_utils

import class ReactiveKit.SerialDisposable

final public class StreamOwner<ValueT, NextT, ErrorT: Error> {

    let barrier: Bool

    var stream: AsyncStream<ValueT, NextT, ErrorT>!

    fileprivate var disposeStream: SerialDisposable? = nil
    var observer: ObserverType?

    typealias ObserverType = (AsyncEvent<ValueT, NextT, ErrorT>) -> Void
    typealias OnComplete   = (StreamOwner<ValueT, NextT, ErrorT>) -> Void
    fileprivate let onComplete: OnComplete

    init<T: AsyncStreamType>(stream: T, observer: @escaping ObserverType, barrier: Bool, onComplete: @escaping OnComplete) where T.ValueT == ValueT, T.NextT == NextT, T.ErrorT == ErrorT {

        self.stream     = stream.map(id_)
        self.observer   = observer
        self.barrier    = barrier
        self.onComplete = onComplete
    }

    func performStream() {

        self.disposeStream = SerialDisposable(otherDisposable: nil)

        let observer = self.observer!
        let dispose = stream.on(completed: { [weak self] in self?.complete() }).observe(observer)

        if let dispose_ = self.disposeStream {
            dispose_.otherDisposable = dispose
        }
    }

    func dispose() {

        disposeStream?.dispose()
        complete()
    }

    fileprivate func complete() {

        onComplete(self)
        stream = nil
        disposeStream = nil
    }
}
