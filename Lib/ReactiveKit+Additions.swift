//
//  ReactiveKit+Additions.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 10/02/16.
//  Copyright © 2016 AppDaddy. All rights reserved.
//

import Foundation

import ReactiveKit

public func combineLatest<S: SequenceType, T where S.Generator.Element == Stream<T>>(producers: S) -> Stream<[T]> {

    let size = Array(producers).count

    if size == 0 {
        return Stream<[T]>.just([])
    }

    return Stream { observer in

        let queue = Queue(name: "com.ReactiveKit.ReactiveKit.combineLatest")

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

        for (index, stream) in producers.enumerate() {

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

public extension RawStreamType where Event.Element: OptionalType, Event.Element.Wrapped: Equatable {

    public func distinctOptional2() -> Stream<Event.Element.Wrapped?> {

        return Stream { observer in
            var lastEvent: Event.Element.Wrapped? = nil
            var firstEvent: Bool = true
            return self.observe { event in

                if event.isTermination {

                    observer.completed()
                    return
                }

                if let value = event.element {

                    switch (lastEvent, value._unbox) {
                    case (.None, .Some(let new)):
                        firstEvent = false
                        observer.next(new)
                    case (.Some, .None):
                        firstEvent = false
                        observer.next(nil)
                    case (.None, .None) where firstEvent:
                        firstEvent = false
                        observer.next(nil)
                    case (.Some(let old), .Some(let new)) where old != new:
                        firstEvent = false
                        observer.next(new)
                    default:
                        break
                    }

                    lastEvent = value._unbox
                }
            }
        }
    }
}

public extension StreamType where Element: OptionalType, Element.Wrapped: Equatable {

    public func distinctOptional2() -> Stream<Element.Wrapped?> {
        return rawStream.distinctOptional2()
    }
}

////TODO test
//public func combineLatest<S: SequenceType, T, N, E where S.Generator.Element == AsyncStream<T, N, E>, E: ErrorType>(producers: S) -> AsyncStream<[T], N, E> {
//    
//    let size = Array(producers).count
//    
//    if size == 0 {
//        return AsyncStream.succeeded(with: [])
//    }
//    
//    return create { observer in
//        
//        let queue = Queue(name: "com.ReactiveKit.ReactiveKit.combineLatest")
//        
//        var results = [Int:AsyncEvent<T, N, E>]()
//        
//        let dispatchIfPossible = { (currIndex: Int, currEv: AsyncEvent<T, N, E>) -> () in
//            
//            if let index = results.indexOf({ $0.1.isFailure }) {
//                
//                let el = results[index]
//                observer(.Failure(el.1.error!))
//            }
//            
//            if results.count == size && results.all({ $0.1.isSuccess }) {
//                
//                let els = results.map { $0.1.value! }
//                observer(.Success(els))
//            }
//            
//            if case .Next(let val) = currEv {
//                observer(.Next(val))
//            }
//        }
//        
//        var disposes = [Disposable]()
//        
//        for (index, stream) in producers.enumerate() {
//            
//            let dispose = stream.observe(on: nil) { event in
//                queue.sync {
//                    results[index] = event
//                    dispatchIfPossible(index, event)
//                }
//            }
//            
//            disposes.append(dispose)
//        }
//        
//        return CompositeDisposable(disposes)
//    }
//}

//public extension StreamType_old where Event: OptionalType, Event.Wrapped: Equatable {
//    
//    public func distinctOptional2() -> Stream_old<Event.Wrapped?> {
//        return create_old { observer in
//            var lastEvent: Event.Wrapped? = nil
//            var firstEvent: Bool = true
//            return self.observe(on: nil) { event in
//                
//                switch (lastEvent, event._unbox) {
//                case (.None, .Some(let new)):
//                    firstEvent = false
//                    observer(new)
//                case (.Some, .None):
//                    firstEvent = false
//                    observer(nil)
//                case (.None, .None) where firstEvent:
//                    firstEvent = false
//                    observer(nil)
//                case (.Some(let old), .Some(let new)) where old != new:
//                    firstEvent = false
//                    observer(new)
//                default:
//                    break
//                }
//                
//                lastEvent = event._unbox
//            }
//        }
//    }
//}
