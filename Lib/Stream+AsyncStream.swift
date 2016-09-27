//
//  Stream+AsyncStream.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 05/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import class ReactiveKit.SerialDisposable
import ReactiveKit_old//???

public extension StreamType_old where Event: AsyncStreamType {

    //TODO test
    public func merge() -> AsyncStream<Event.Value, Event.Next, Event.Error> {
        return create { observer in
            let compositeDisposable = CompositeDisposable()

            compositeDisposable += self.observe(on: nil) { task in
                compositeDisposable += task.observe(on: nil) { event in
                    switch event {
                    case .Next, .Failure:
                        observer(event)
                    case .Success:
                        break
                    }
                }
            }
            return compositeDisposable
        }
    }

    public func switchToLatest() -> AsyncStream<Event.Value, Event.Next, Event.Error>  {
        return create { observer in

            let serialDisposable = SerialDisposable(otherDisposable: nil)
            let compositeDisposable = CompositeDisposable([serialDisposable])

            compositeDisposable += self.observe(on: nil) { task in

                serialDisposable.otherDisposable?.dispose()
                serialDisposable.otherDisposable = task.observe(on: nil) { event in

                    switch event {
                    case .Failure(let error):
                        observer(.Failure(error))
                    case .Success(let value):
                        observer(.Success(value))
                    case .Next(let value):
                        observer(.Next(value))
                    }
                }
            }

            return compositeDisposable
        }
    }

    //TODO test
    public func concat() -> AsyncStream<Event.Value, Event.Next, Event.Error>  {
        return create { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            let compositeDisposable = CompositeDisposable([serialDisposable])

            var innerCompleted: Bool = true

            var taskQueue: [Event] = []

            var startNextOperation: (() -> ())! = nil
            startNextOperation = {
                innerCompleted = false
                let task = taskQueue.removeAtIndex(0)

                serialDisposable.otherDisposable?.dispose()
                serialDisposable.otherDisposable = task.observe(on: nil) { event in
                    switch event {
                    case .Failure(let error):
                        observer(.Failure(error))
                    case .Success:
                        innerCompleted = true
                        if taskQueue.count > 0 {
                            startNextOperation()
                        }
                    case .Next(let value):
                        observer(.Next(value))
                    }
                }
            }

            let addToQueue = { (task: Event) -> () in
                taskQueue.append(task)
                if innerCompleted {
                    startNextOperation()
                }
            }

            compositeDisposable += self.observe(on: nil) { task in
                addToQueue(task)
            }

            return compositeDisposable
        }
    }
}

public extension StreamType_old {

    public func flatMap<T: AsyncStreamType>(strategy: AsyncStreamFlatMapStrategy, transform: Event -> T) -> AsyncStream<T.Value, T.Next, T.Error> {
        switch strategy {
        case .Latest:
            return map(transform).switchToLatest()
        case .Merge:
            return map(transform).merge()
        case .Concat:
            return map(transform).concat()
        }
    }
}
