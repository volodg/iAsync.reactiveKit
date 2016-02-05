//
//  AsyncEvent+Additions.swift
//  iAsync.reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 Volodymyr. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import ReactiveKit

public extension AsyncStreamType {

    typealias Event = AsyncEvent<Value, Progress, Error>

    public func mapValue<U>(transform: Value -> U) -> Stream<AsyncEvent<U, Progress, Error>> {
        return create { observer in
            return self.observe(on: nil) { event in

                switch event {
                case .Success(let value):
                    observer(.Success(transform(value)))
                case .Failure(let error):
                    observer(.Failure(error))
                case .Progress(let progress):
                    observer(.Progress(progress))
//                case .Interrupted:
//                    observer(.Interrupted)
//                case .Unsubscribed:
//                    observer(.Unsubscribed)
                }
            }
        }
    }

    public func mapError<U>(transform: Error -> U) -> Stream<AsyncEvent<Value, Progress, U>> {
        return create { observer in
            return self.observe(on: nil) { event in

                switch event {
                case .Success(let value):
                    observer(.Success(value))
                case .Failure(let error):
                    observer(.Failure(transform(error)))
                case .Progress(let progress):
                    observer(.Progress(progress))
//                case .Interrupted:
//                    observer(.Interrupted)
//                case .Unsubscribed:
//                    observer(.Unsubscribed)
                }
            }
        }
    }

    public func mapProgress<U>(transform: Progress -> U) -> Stream<AsyncEvent<Value, U, Error>> {
        return create { observer in
            return self.observe(on: nil) { event in

                switch event {
                case .Success(let value):
                    observer(.Success(value))
                case .Failure(let error):
                    observer(.Failure(error))
                case .Progress(let progress):
                    observer(.Progress(transform(progress)))
//                case .Interrupted:
//                    observer(.Interrupted)
//                case .Unsubscribed:
//                    observer(.Unsubscribed)
                }
            }
        }
    }

    public func unsubscribe() -> AsyncStream<Value, Progress, Error> {

        return create { observer in

            var disposed = false

            self.observe(on: nil) { event in
                if !disposed {
                    observer(event)
                }
            }

            return BlockDisposable({ () -> () in
                disposed = true
            })
        }
    }

    //TODO test
    public func withEventValue(getter: () -> AsyncEvent<Value, Progress, Error>?, setter: AsyncEvent<Value, Progress, Error> -> Void) -> AsyncStream<Value, Progress, Error> {

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

    //TODO test
    public func mergedObservers() -> AsyncStream<Value, Progress, Error> {

        var observers: [(AsyncEvent<Value, Progress, Error> -> ())?] = []

        return create { observer in

            observers.append(observer)

            if observers.count > 1 {

                let index = observers.count - 1
                return BlockDisposable({ () -> () in

                    observers[index] = nil
                })
            }

            let notify = { (observers: [(AsyncEvent<Value, Progress, Error> -> ())?], event: AsyncEvent<Value, Progress, Error>) in
                observers.forEach { $0?(event) }
            }
            let finishNotify = { (event: AsyncEvent<Value, Progress, Error>) in
                let observers_ = observers
                observers.removeAll()
                notify(observers_, event)
            }

            let dispose = self.observe(on: nil) { event in

                switch event {
                case .Success:
                    finishNotify(event)
                case .Failure:
                    finishNotify(event)
//                case .Interrupted:
//                    finishNotify(event)
//                case .Unsubscribed:
//                    finishNotify(event)
                case .Progress:
                    notify(observers, event)
                }
            }

            return BlockDisposable({ () -> () in

                observers[0] = nil
                if observers.all({ $0 == nil }) {
                    dispose.dispose()
                }
            })
        }
    }
}

public func asyncToStream<Value, Error: ErrorType>(loader: AsyncTypes<Value, Error>.Async) -> AsyncStream<Value, AnyObject, Error> {

    typealias Event = AsyncEvent<Value, AnyObject, Error>

    let result = AsyncStream { (observer: Event -> ()) -> DisposableType? in

        let handler = loader(progressCallback: { (progressInfo) -> () in

            observer(.Progress(progressInfo))
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

public func streamToAsync<Input: AsyncStreamType where Input.Progress == AnyObject>(input: Input) -> AsyncTypes<Input.Value, Input.Error>.Async {

    return { (
        progressCallback: AsyncProgressCallback?,
        stateCallback   : AsyncChangeStateCallback?,
        finishCallback  : AsyncTypes<Input.Value, Input.Error>.DidFinishAsyncCallback?) -> AsyncHandler in

        var finishCallbackHolder = finishCallback
        let finishOnce = { (result: AsyncResult<Input.Value, Input.Error>) -> Void in
            if let finishCallback = finishCallbackHolder {
                finishCallbackHolder = nil
                finishCallback(result: result)
            }
        }

        let dispose = input.observe(on: nil, observer: { event -> () in

            if finishCallbackHolder == nil { return }

            switch event {
            case .Success(let value):
                finishOnce(.Success(value))
            case .Failure(let error):
                finishOnce(.Failure(error))
            case .Progress(let progress):
                progressCallback?(progressInfo: progress)
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
