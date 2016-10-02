//
//  AsyncStream+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils

import ReactiveKit

private final class AsyncObserverHolder<ValueT, NextT, ErrorT: Error> {

    let observer: (AsyncEvent<ValueT, NextT, ErrorT>) -> ()

    init(observer: @escaping (AsyncEvent<ValueT, NextT, ErrorT>) -> ()) {
        self.observer = observer
    }
}

public extension AsyncStreamType {

    public func run() -> Disposable {
        return observe {_ in}
    }

    public func unsubscribe() -> AsyncStream<ValueT, NextT, ErrorT> {

        return AsyncStream { observer in

            typealias Observer = (AsyncEvent<ValueT, NextT, ErrorT>) -> ()
            var observerHolder: ObserverT? = observer

            _ = self.observe { event in
                if let observer = observerHolder {
                    observer(event)
                }
            }

            return BlockDisposable { () in
                observerHolder = nil
            }
        }
    }

    public func withEventValueGetter(_ getter: @escaping () -> AsyncEvent<ValueT, NextT, ErrorT>?) -> AsyncStream<ValueT, NextT, ErrorT> {

        return AsyncStream { observer in

            let event = getter()

            if let event = event {
                observer(event)
                if event.isTerminal { return NonDisposable.instance }
            }

            return self.observe(observer)
        }
    }

    public func withEventValueSetter(_ setter: @escaping (AsyncEvent<ValueT, NextT, ErrorT>) -> Void) -> AsyncStream<ValueT, NextT, ErrorT> {

        return AsyncStream { observer in

            return self.observe { event in

                setter(event)
                observer(event)
            }
        }
    }

    public func mergedObservers(_ limit: Int = Int.max) -> AsyncStream<ValueT, NextT, ErrorT> {

        typealias ObserverHolder = AsyncObserverHolder<ValueT, NextT, ErrorT>
        var observers: [ObserverHolder] = []
        var dispose: Disposable?

        var buffer = [NextT]()

        return AsyncStream { observer in

            let observerHolder = ObserverHolder(observer: observer)
            observers.append(observerHolder)

            let removeObserver = { () in

                let observers_ = observers
                for (index, observer) in observers_.enumerated() {
                    if observer === observerHolder {
                        observers.remove(at: index)
                        break
                    }
                }
                if observers.isEmpty {
                    if let dispose_ = dispose {
                        dispose = nil
                        dispose_.dispose()
                    }
                }
            }

            if observers.count > 1 {
                buffer.forEach { observer(.next($0)) }
                return BlockDisposable( removeObserver )
            }

            let notify = { (observers: [ObserverHolder], event: AsyncEvent<ValueT, NextT, ErrorT>) in
                observers.forEach { $0.observer(event) }
            }
            let finishNotify = { (event: AsyncEvent<ValueT, NextT, ErrorT>) in
                let observers_ = observers
                observers.removeAll()
                notify(observers_, event)
            }

            dispose = self.observe { event in

                switch event {
                case .success, .failure:
                    finishNotify(event)
                case .next(let next):
                    if buffer.count < limit {
                        buffer.append(next)
                    }
                    if buffer.count > limit {
                        buffer = Array(buffer.suffix(from: 1))
                    }
                    notify(observers, event)
                }
            }

            return BlockDisposable( removeObserver )
        }
    }
}

public func asyncStreamWithSameThreadJob<ValueT, NextT, ErrorT: Error>(_ job: @escaping ((NextT) -> Void) -> Result<ValueT, ErrorT>) -> AsyncStream<ValueT, NextT, ErrorT> {

    typealias Event = AsyncEvent<ValueT, NextT, ErrorT>

    return AsyncStream { observer in

        var observerHolder: ((Event) -> ())? = observer

        let result = job { next in
            observerHolder?(.next(next))
        }

        switch result {
        case .success(let value):
            observerHolder?(.success(value))
        case .failure(let error):
            observerHolder?(.failure(error))
        }

        return BlockDisposable {

            observerHolder = nil
        }
    }
}

public func asyncStreamWithJob<ValueT, NextT, ErrorT: Error>(
    _ queueName: String? = nil,
    job: @escaping ((NextT) -> Void) -> Result<ValueT, ErrorT>) -> AsyncStream<ValueT, NextT, ErrorT> {

    typealias Event = AsyncEvent<ValueT, NextT, ErrorT>

    return AsyncStream { observer in

        var observerHolder: ((Event) -> ())? = observer

        DispatchQueue.global().async {

            let result = job { next in
                DispatchQueue.main.async {
                    observerHolder?(.next(next))
                }
            }

            DispatchQueue.main.async {
                switch result {
                case .success(let value):
                    observerHolder?(.success(value))
                case .failure(let error):
                    observerHolder?(.failure(error))
                }
            }
        }

        return BlockDisposable {
            observerHolder = nil
        }
    }
}
