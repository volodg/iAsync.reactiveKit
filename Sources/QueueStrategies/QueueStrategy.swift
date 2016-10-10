//
//  QueueStrategy.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright © 2014 EmbeddedSources. All rights reserved.
//

import Foundation

public protocol QueueStrategy {

    associatedtype ValueT
    associatedtype NextT
    associatedtype ErrorT: Error

    static func nextPendingStream(queueState: QueueState<ValueT, NextT, ErrorT>) -> StreamOwner<ValueT, NextT, ErrorT>?
}

extension QueueStrategy {

    internal static func executePendingStreamFor(queueState: QueueState<ValueT, NextT, ErrorT>, pendingStream: StreamOwner<ValueT, NextT, ErrorT>) {

        var objectIndex: Int?

        for (index, stream) in queueState.pendingStreams.enumerated() {
            if stream === pendingStream {
                objectIndex = index
                break
            }
        }

        if let objectIndex = objectIndex {
            queueState.pendingStreams.remove(at: objectIndex)
        }

        queueState.activeStreams.append(pendingStream)

        pendingStream.performStream()
    }
}
