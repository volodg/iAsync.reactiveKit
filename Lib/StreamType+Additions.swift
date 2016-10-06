//
//  StreamType+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 09/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import ReactiveKit

extension SignalProtocol {

    public func throttleIf(_ seconds: Double, predicate: @escaping (Element) -> Bool, on queue: DispatchQueue) -> Signal<Element, Error> {

        return Signal { observer in

            var timerInFlight: Bool = false
            var latestEvent: Element! = nil
            var latestEventDate: Date! = nil

            var tryDispatch: (() -> Void)?
            tryDispatch = {
                if latestEventDate.addingTimeInterval(seconds).compare(Date()) == ComparisonResult.orderedAscending {
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
            compositeDisposable.add(disposable: self.observe { event in

                switch event {
                case .next(let element):

                    if !predicate(element) {

                        latestEvent     = nil
                        latestEventDate = nil
                        timerInFlight   = false

                        observer.next(element)
                        return
                    }

                    latestEvent = element
                    latestEventDate = Date()

                    guard timerInFlight == false else { return }
                    tryDispatch?()
                case .failed:
                    observer.on(event)
                case .completed:
                    observer.on(event)
                }
            })
            return compositeDisposable
        }
    }

    public func pausable<S: SignalProtocol>(_ by: S, delayAfterPause: Double, on queue: DispatchQueue) -> Signal<Element, Error> where S.Element == Bool {

        return Signal { observer in

            var allowed: Bool = false

            var skipedEvent: Event<Element, Error>?

            let compositeDisposable = CompositeDisposable()
            compositeDisposable.add(disposable: by.observeNext { value in

                allowed = value
                if allowed {
                    queue.after(when: delayAfterPause, block: {

                        guard let skipedEvent_ = skipedEvent else { return }
                        skipedEvent = nil

                        if allowed {
                            observer.on(skipedEvent_)
                        }
                    })
                }
            })

            compositeDisposable.add(disposable: self.observe { event in
                if allowed {
                    skipedEvent = nil
                    observer.on(event)
                } else {
                    skipedEvent = event
                }
            })

            return compositeDisposable
        }
    }

    public func pausable2<R: SignalProtocol>(_ by: R) -> Signal<Element, Error> where R.Element == Bool {

        return Signal { observer in

            var allowed: Bool = true

            var skipedEvent: Event<Element, Error>?

            let compositeDisposable = CompositeDisposable()
            compositeDisposable += by.observeNext { value in

                allowed = value

                if allowed, let skipedEvent_ = skipedEvent {
                    skipedEvent = nil
                    observer.observer(skipedEvent_)
                }
            }

            compositeDisposable += self.observe { event in
                if event.isTerminal {
                    skipedEvent = nil
                    observer.observer(event)
                } else if allowed {
                    skipedEvent = nil
                    observer.observer(event)
                } else {
                    skipedEvent = event
                }
            }

            return compositeDisposable
        }
    }
}

public extension SignalProtocol {

//    public func flatMap<U: SignalProtocol>(_ transform: (Element) -> U) -> Signal<Element, Error> {
//        return flatMap(.Latest, transform: transform)
//    }
}
