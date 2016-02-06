//
//  AsyncStream+Additions.swift
//  iAsync.reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import ReactiveKit

private class AsyncObserverHolder<Value, Next, Error: ErrorType> {

    let observer: AsyncEvent<Value, Next, Error> -> ()

    init(observer: AsyncEvent<Value, Next, Error> -> ()) {
        self.observer = observer
    }
}

public extension AsyncStreamType {

    typealias Event = AsyncEvent<Value, Next, Error>

    public func mapValue<U>(transform: Value -> U) -> AsyncStream<U, Next, Error> {
        return create { observer in
            return self.observe(on: nil) { event in

                switch event {
                case .Success(let value):
                    observer(.Success(transform(value)))
                case .Failure(let error):
                    observer(.Failure(error))
                case .Next(let next):
                    observer(.Next(next))
                }
            }
        }
    }

    public func mapNext<U>(transform: Next -> U?) -> AsyncStream<Value, U, Error> {
        return create { observer in
            return self.observe(on: nil) { event in

                switch event {
                case .Success(let value):
                    observer(.Success(value))
                case .Failure(let error):
                    observer(.Failure(error))
                case .Next(let next):
                    if let next = transform(next) {
                        observer(.Next(next))
                    }
                }
            }
        }
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

    public func withEventValue(getter: () -> AsyncEvent<Value, Next, Error>?, setter: AsyncEvent<Value, Next, Error> -> Void) -> AsyncStream<Value, Next, Error> {

        return create { observer in

            let event = getter()

            if let event = event {

                observer(event)
                return nil
            }

            return self.observe(on: nil) { event in

                setter(event)
                observer(event)
            }
        }
    }

    public func mergedObservers() -> AsyncStream<Value, Next, Error> {

        typealias ObserverHolder = AsyncObserverHolder<Value, Next, Error>
        var observers: [ObserverHolder] = []
        var dispose: DisposableType?

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
                case .Success:
                    finishNotify(event)
                case .Failure:
                    finishNotify(event)
                case .Next:
                    notify(observers, event)
                }
            }

            return BlockDisposable( removeObserver )
        }
    }
}

public func asyncStreamWithJob<Value, Next, Error: ErrorType>(
    queueName: String? = nil,
    job: (Next -> Void) -> Result<Value, Error>) -> AsyncStream<Value, Next, Error> {

    typealias Event = AsyncEvent<Value, Next, Error>

    return AsyncStream { (observer: Event -> ()) -> DisposableType? in

        var finished = false

        let queue = Queue(name: queueName ?? "com.ReactiveKit.ReactiveKit.AsyncStreamJob")

        var observerHolder: (Event -> ())? = observer

        Queue.global.async({ 

            let result = job { next -> Void in
                queue.sync {
                    if finished { return }
                    observerHolder?(.Next(next))
                }
            }

            queue.sync {
                switch result {
                case .Success(let value):
                    observerHolder?(.Success(value))
                case .Failure(let error):
                    observerHolder?(.Failure(error))
                }
            }
        })

        return BlockDisposable {
            queue.sync {
                observerHolder = nil
                finished = true
            }
        }
    }
}

public func asyncToStream<Value, Error: ErrorType>(loader: AsyncTypes<Value, Error>.Async) -> AsyncStream<Value, AnyObject, Error> {

    typealias Event = AsyncEvent<Value, AnyObject, Error>

    let result = AsyncStream { (observer: Event -> ()) -> DisposableType? in

        let handler = loader(progressCallback: { (progressInfo) -> () in

            observer(.Next(progressInfo))
        }, stateCallback: { (state) -> () in

            //ignore, still not used
            fatalError()
        }, finishCallback: { (result) -> Void in

            switch result {
            case .Success(let value):
                observer(.Success(value))
            case .Failure(let error):
                observer(.Failure(error))
            case .Interrupted:
                break
            case .Unsubscribed:
                break
            }
        })

        return BlockDisposable({ () -> () in

            handler(task: .Cancel)
        })
    }

    return result
}

public extension AsyncStreamType where Self.Next == AnyObject {

    public func toAsync() -> AsyncTypes<Self.Value, Self.Error>.Async {

        return { (
            progressCallback: AsyncProgressCallback?,
            stateCallback   : AsyncChangeStateCallback?,
            finishCallback  : AsyncTypes<Self.Value, Self.Error>.DidFinishAsyncCallback?) -> AsyncHandler in

            var progressCallbackHolder = progressCallback
            var finishCallbackHolder   = finishCallback

            let finishOnce = { (result: AsyncResult<Self.Value, Self.Error>) -> Void in

                progressCallbackHolder = nil

                if let finishCallback = finishCallbackHolder {
                    finishCallbackHolder   = nil
                    finishCallback(result: result)
                }
            }

            let dispose = self.observe(on: nil, observer: { event -> () in

                if finishCallbackHolder == nil { return }

                switch event {
                case .Success(let value):
                    finishOnce(.Success(value))
                case .Failure(let error):
                    finishOnce(.Failure(error))
                case .Next(let next):
                    progressCallbackHolder?(progressInfo: next)
                }
            })

            return { (task: AsyncHandlerTask) -> Void in

                switch task {
                case .Cancel:
                    dispose.dispose()
                    finishOnce(.Interrupted)
                case .UnSubscribe:
                    finishOnce(.Unsubscribed)
                case .Resume:
                    fatalError()
                case .Suspend:
                    fatalError()
                }
            }
        }
    }
}
