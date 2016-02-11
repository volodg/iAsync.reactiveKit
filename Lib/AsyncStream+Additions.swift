//
//  AsyncStream+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit

private class AsyncObserverHolder<Value, Next, Error: ErrorType> {

    let observer: AsyncEvent<Value, Next, Error> -> ()

    init(observer: AsyncEvent<Value, Next, Error> -> ()) {
        self.observer = observer
    }
}

public extension AsyncStreamType {

    typealias Event = AsyncEvent<Value, Next, Error>

    public func run() -> DisposableType {
        return observe(on: nil, observer: {_ in})
    }

    public func unsubscribe() -> AsyncStream<Value, Next, Error> {

        return create { observer in

            typealias Observer = AsyncEvent<Value, Next, Error> -> ()
            var observerHolder: Observer? = observer

            self.observe(on: nil) { event in
                if let observer = observerHolder {
                    observer(event)
                }
            }

            return BlockDisposable({ () -> () in
                observerHolder = nil
            })
        }
    }

    public func withEventValueGetter(getter: () -> AsyncEvent<Value, Next, Error>?) -> AsyncStream<Value, Next, Error> {

        return create { observer in

            let event = getter()

            if let event = event {
                observer(event)
                if event.isTerminal { return nil }
            }

            return self.observe(on: nil, observer: observer)
        }
    }

    public func withEventValueSetter(setter: AsyncEvent<Value, Next, Error> -> Void) -> AsyncStream<Value, Next, Error> {

        return create { observer in

            return self.observe(on: nil) { event in

                setter(event)
                observer(event)
            }
        }
    }

    public func mergedObservers(limit: Int = Int.max) -> AsyncStream<Value, Next, Error> {

        typealias ObserverHolder = AsyncObserverHolder<Value, Next, Error>
        var observers: [ObserverHolder] = []
        var dispose: DisposableType?

        var buffer = [Next]()

        return create { observer in

            let observerHolder = ObserverHolder(observer: observer)
            observers.append(observerHolder)

            let removeObserver = { () -> Void in

                let observers_ = observers
                for (index, observer) in observers_.enumerate() {
                    if observer === observerHolder {
                        observers.removeAtIndex(index)
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
                buffer.forEach { observer(.Next($0)) }
                return BlockDisposable( removeObserver )
            }

            let notify = { (observers: [ObserverHolder], event: AsyncEvent<Value, Next, Error>) in
                observers.forEach { $0.observer(event) }
            }
            let finishNotify = { (event: AsyncEvent<Value, Next, Error>) in
                let observers_ = observers
                observers.removeAll()
                notify(observers_, event)
            }

            dispose = self.observe(on: nil) { event in

                switch event {
                case .Success, .Failure:
                    finishNotify(event)
                case .Next(let next):
                    if buffer.count < limit {
                        buffer.append(next)
                    }
                    if buffer.count > limit {
                        buffer = Array(buffer.suffixFrom(1))
                    }
                    notify(observers, event)
                }
            }

            return BlockDisposable( removeObserver )
        }
    }
}

public func asyncStreamWithSameThreadJob<Value, Next, Error: ErrorType>(job: (Next -> Void) -> Result<Value, Error>) -> AsyncStream<Value, Next, Error> {

    typealias Event = AsyncEvent<Value, Next, Error>

    return create { observer in

        var observerHolder: (Event -> ())? = observer

        Queue.global.async({

            let result = job { next -> Void in
                observerHolder?(.Next(next))
            }

            switch result {
            case .Success(let value):
                observerHolder?(.Success(value))
            case .Failure(let error):
                observerHolder?(.Failure(error))
            }
        })

        return BlockDisposable {

            observerHolder = nil
        }
    }
}

public func asyncStreamWithJob<Value, Next, Error: ErrorType>(
    queueName: String? = nil,
    job: (Next -> Void) -> Result<Value, Error>) -> AsyncStream<Value, Next, Error> {

    typealias Event = AsyncEvent<Value, Next, Error>

    return create { observer in

        var observerHolder: (Event -> ())? = observer

        Queue.global.async {

            let result = job { next -> Void in
                Queue.main.async {
                    observerHolder?(.Next(next))
                }
            }

            Queue.main.async {
                switch result {
                case .Success(let value):
                    observerHolder?(.Success(value))
                case .Failure(let error):
                    observerHolder?(.Failure(error))
                }
            }
        }

        return BlockDisposable {
            observerHolder = nil
        }
    }
}

public func asyncStreamJob(job: () -> Void) -> AsyncStream<Void, Void, NSError> {

    return asyncStreamWithJob { _ in
        job()
        return .Success(())
    }
}
