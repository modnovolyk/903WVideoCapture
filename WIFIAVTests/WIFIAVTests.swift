//
//  WIFIAVTests.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 2/1/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Foundation

extension Data {
    func withUnsafeRawBufferPointer<ResultType>(_ body: (UnsafeRawBufferPointer) throws -> ResultType) rethrows -> ResultType {
        return try self.withUnsafeBytes { (bytesPtr: UnsafePointer<UInt8>) -> ResultType in
            return try body(UnsafeRawBufferPointer(start: bytesPtr, count: count))
        }
    }
}

extension Array {
    func ignoreUDPHeader() -> ArraySlice<Element> {
        return self.suffix(from: 28)
    }
}
