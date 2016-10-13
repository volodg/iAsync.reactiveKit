//
//  LimitedAsyncStreamsQueue.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 07/02/16.
//  Copyright © 2016 EmbeddedSystems. All rights reserved.
//

import Foundation

import iAsync_utils

import class ReactiveKit.BlockDisposable

//TODO test
final public class LimitedAsyncStreamsQueue<Strategy: QueueStrategy> {

    private let state = QueueState<Strategy.ValueT, Strategy.NextT, Strategy.ErrorT>()

    public typealias StreamT = AsyncStream<Strategy.ValueT, Strategy.NextT, Strategy.ErrorT>
    public typealias OwnerT  = StreamOwner<Strategy.ValueT, Strategy.NextT, Strategy.ErrorT>

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

    //todo rename?
    private func hasStreamsReadyToStartForPendingStream(_ pendingStream: OwnerT) -> Bool {

        if pendingStream.barrier {
            return state.activeStreams.count == 0
        }

        let result = limitCount > state.activeStreams.count && state.pendingStreams.count > 0

        if result {
            return state.activeStreams.all { !$0.barrier }
        }

        return result
    }

    private func nextPendingStream() -> OwnerT? {
        return Strategy.nextPendingStream(queueState: state)
    }

    private func performPendingStreams() {

        var pendingStream = nextPendingStream()

        while let nextStream = pendingStream, hasStreamsReadyToStartForPendingStream(nextStream) {

            Strategy.executePendingStreamFor(queueState: state, pendingStream: nextStream)
            pendingStream = nextPendingStream()
        }
    }

    //todo rename?
    public func balancedStream<T: AsyncStreamType>
        (_ stream: T, barrier: Bool) -> StreamT where Strategy.ValueT == T.ValueT, Strategy.NextT == T.NextT, Strategy.ErrorT == T.ErrorT {

        return AsyncStream { observer in

            let streamOwner = StreamOwner(stream: stream, observer: observer, barrier: barrier, onComplete: {
                self.didFinishStream($0)
            })

            weak var weakStreamOwner = streamOwner

            self.state.pendingStreams.append(streamOwner)

            self.performPendingStreams()

            return BlockDisposable { weakStreamOwner?.dispose() }
        }
    }

    //todo rename?
    public func barrierBalancedStream(_ stream: StreamT) -> StreamT {

        return balancedStream(stream, barrier:true)
    }

    //todo rename?
    private func didFinishStream(_ stream: OwnerT) {

        state.tryRemove(pendingStream: stream)

        if state.tryRemove(activeStream: stream) {
            performPendingStreams()
        }
    }
}
