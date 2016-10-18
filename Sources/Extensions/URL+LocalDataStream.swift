//
//  URL+LocalDataStream.swift
//  iAsync_reactiveKit
//
//  Created by Gorbenko Vladimir on 25.11.15.
//  Copyright © 2015 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_utils
import ReactiveKit

import protocol ReactiveKit.Disposable

extension URL {

    public func localDataStream() -> AsyncStream<Data, AnyObject, ErrorWithContext> {

        return AsyncStream { observer -> Disposable in

            self.getLocalData(onData: { data in

                observer(.success(data))
            }) { error in

                observer(.failure(error))
            }
            return NonDisposable.instance
        }
    }
}
