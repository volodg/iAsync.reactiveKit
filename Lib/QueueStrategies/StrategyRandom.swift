//
//  StrategyRandom.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright © 2014 EmbeddedSources. All rights reserved.
//

import Foundation

final internal class StrategyRandom<Value, Next, Error: ErrorType> : QueueStrategy {

    static func nextPendingStream(queueState: QueueState<Value, Next, Error>) -> StreamOwner<Value, Next, Error>? {

        let index = Int(arc4random_uniform(UInt32(queueState.pendingStreams.count)))

        let result = queueState.pendingStreams[index]
        return result
    }
}
