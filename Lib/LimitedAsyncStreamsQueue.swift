//
//  LimitedAsyncStreamsQueue.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 07/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils

import ReactiveKit

final public class LimitedAsyncStreamsQueue<Strategy: QueueStrategy> {

    private let state = QueueState<Strategy.Value, Strategy.Next, Strategy.Error>()

    public typealias StreamT = AsyncStream<Strategy.Value, Strategy.Next, Strategy.Error>
    public typealias OwnerT  = StreamOwner<Strategy.Value, Strategy.Next, Strategy.Error>

    public var limitCount: Int {
        didSet {
            performPendingStreams()
        }
    }

    public convenience init() {

        self.init(limitCount: 10)
    }

    public var allStreamsCount: Int {

        return state.activeStreams.count + state.pendingStreams.count
    }

    public init(limitCount: Int) {

        self.limitCount = limitCount
    }

    public func cancelAllActiveStreams() {

        for activeStream in self.state.activeStreams {

            activeStream.dispose()
        }
    }

    private func hasStreamsReadyToStartForPendingStream(pendingStream: OwnerT) -> Bool {

        if pendingStream.barrier {

            return state.activeStreams.count == 0
        }

        let result = limitCount > state.activeStreams.count && state.pendingStreams.count > 0

        if result {

            return state.activeStreams.all { (activeStream: OwnerT) -> Bool in
                return !activeStream.barrier
            }
        }

        return result
    }

    private func nextPendingStream() -> OwnerT? {
        return Strategy.nextPendingStream(state)
    }

    private func performPendingStreams() {

        var pendingStream = nextPendingStream()

        while let nextStream = pendingStream where hasStreamsReadyToStartForPendingStream(nextStream) {

            Strategy.executePendingStream(state, pendingStream: nextStream)
            pendingStream = nextPendingStream()
        }
    }

    public func balancedStream<T: AsyncStreamType where Strategy.Value == T.Value, Strategy.Next == T.Next, Strategy.Error == T.Error>
        (stream: T, barrier: Bool) -> StreamT {

        return create { observer in

            let streamOwner = StreamOwner(stream: stream, observer: observer, barrier: barrier, onComplete: {
                self.didFinishStream($0)
            })

            weak var weakStreamOwner = streamOwner

            self.state.pendingStreams.append(streamOwner)

            self.performPendingStreams()

            return BlockDisposable { weakStreamOwner?.dispose() }
        }
    }

    public func barrierBalancedStream(stream: StreamT) -> StreamT {

        return balancedStream(stream, barrier:true)
    }

    private func didFinishStream(stream: OwnerT) {

        state.tryRemovePendingStream(stream)

        if state.tryRemoveActiveStream(stream) {
            performPendingStreams()
        }
    }
}
