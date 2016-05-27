//
//  StrategyFifo.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright © 2014 EmbeddedSources. All rights reserved.
//

import Foundation

final public class StrategyFifo<Value, Next, Error: ErrorType> : QueueStrategy {

    public static func nextPendingStream(queueState: QueueState<Value, Next, Error>) -> StreamOwner<Value, Next, Error>? {
        return queueState.pendingStreams.first
    }
}
