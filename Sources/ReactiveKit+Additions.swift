//
//  ReactiveKit+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 10/02/16.
//  Copyright © 2016 AppDaddy. All rights reserved.
//

import Foundation

import ReactiveKit

public func combineLatest<S: Sequence, T>(_ producers: S) -> Signal1<[T]> where S.Iterator.Element == Signal1<T> {

    let size = Array(producers).count

    if size == 0 {
        return Signal1<[T]>.just([])
    }

    return Signal1 { observer in

        let queue = DispatchQueue(label: "com.ReactiveKit.ReactiveKit.combineLatest")

        var results = [Int:T]()

        var varEvent: [T]! = nil

        let dispatchIfPossible = { (currIndex: Int) -> () in

            if results.count == size {

                if varEvent == nil {
                    varEvent = [T]()

                    for i in 0..<size {
                        varEvent.append(results[i]!)
                    }
                } else {

                    varEvent[currIndex] = results[currIndex]!
                }

                observer.next(varEvent)
            }
        }

        var disposes = [Disposable]()

        for (index, stream) in producers.enumerated() {

            let dispose = stream.observeNext { event in
                queue.sync {
                    results[index] = event
                    dispatchIfPossible(index)
                }
            }

            disposes.append(dispose)
        }

        return CompositeDisposable(disposes)
    }
}

public extension SignalProtocol where Element: OptionalProtocol, Element.Wrapped: Equatable, Error == NoError {

    public func distinctOptional2() -> Signal1<Element.Wrapped?> {

        return Signal { observer in
            var lastEvent: Element.Wrapped? = nil
            var firstEvent: Bool = true
            return self.observe { event in

                if event.isTerminal {

                    observer.completed()
                    return
                }

                switch event {
                case .next(let value):
                    switch (lastEvent, value._unbox) {
                    case (.none, .some(let new)):
                        firstEvent = false
                        observer.next(new)
                    case (.some, .none):
                        firstEvent = false
                        observer.next(nil)
                    case (.none, .none) where firstEvent:
                        firstEvent = false
                        observer.next(nil)
                    case (.some(let old), .some(let new)) where old != new:
                        firstEvent = false
                        observer.next(new)
                    default:
                        break
                    }

                    lastEvent = value._unbox
                default:
                    fatalError()
                }
            }
        }
    }
}

public extension SignalProtocol {

    /// Throttle the signal to emit at most one element per given `seconds` interval.
    public func throttle2(seconds: Double) -> Signal<Element, Error> {
        return Signal { observer in

            let queue = DispatchQueue.main

            var timerInFlight: Bool = false
            var latestEvent: Element! = nil
            var lastEventTime: DispatchTime = DispatchTime.now() - 1

            var tryDispatch: (() -> Void)?
            tryDispatch = {
                let now = DispatchTime.now()

                if now.rawValue > (lastEventTime + seconds).rawValue {
                    timerInFlight = false
                    observer.next(latestEvent)
                } else {
                    timerInFlight = true
                    queue.after(when: seconds) {
                        if timerInFlight {
                            timerInFlight = false
                            tryDispatch?()
                        }
                    }
                }
            }

            let blockDisposable = BlockDisposable { tryDispatch = nil }
            let compositeDisposable = CompositeDisposable([blockDisposable])

            let disposable = self.observe { event in
                switch event {
                case .next(let element):

                    latestEvent = element
                    tryDispatch?()

                default:
                    observer.on(event)
                }
            }

            compositeDisposable.add(disposable: disposable)

            return compositeDisposable
        }
    }
}
