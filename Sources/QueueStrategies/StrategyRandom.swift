//
//  StrategyRandom.swift
//  iAsync_reactiveKit
//
//  Created by Vladimir Gorbenko on 09.07.14.
//  Copyright © 2014 EmbeddedSources. All rights reserved.
//

import Foundation

final internal class StrategyRandom<ValueT, NextT, ErrorT: Error> : QueueStrategy {

    static func nextPendingStream(queueState: QueueState<ValueT, NextT, ErrorT>) -> StreamOwner<ValueT, NextT, ErrorT>? {

        let index = Int(arc4random_uniform(UInt32(queueState.pendingStreams.count)))

        let result = queueState.pendingStreams[index]
        return result
    }
}
