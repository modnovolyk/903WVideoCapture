//
//  RawH264Buffer.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 2/1/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Foundation

protocol NaluBuffer {
    var delegate: NaluBufferDelegate? { get set }
    var length: Int { get }
    var bytes: Data { get }
    
    init(length: Int, delegate: NaluBufferDelegate?)
    
    func append(_ data: Data)
    func flush()
}

protocol NaluBufferDelegate: class {
    func didGatherUp(frame: Data, in buffer: NaluBuffer)
    func didFail(with error: NaluBufferError, in buffer: NaluBuffer)
}

enum NaluBufferError: Error {
    case bufferTooSmall
    case notEnoughSpace
}

class RawH264NaluBuffer: NaluBuffer {
    weak var delegate: NaluBufferDelegate?
    let length: Int
    
    var bytes: Data {
        return Data(bytes: buffer, count: endIndex)
    }
    
    private let buffer: UnsafeMutablePointer<UInt8>
    private(set) var endIndex = 0

    required init(length: Int, delegate: NaluBufferDelegate? = nil) {
        self.length = length
        self.delegate = delegate
        
        buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
    }
    
    deinit {
        buffer.deallocate(capacity: length)
    }
    
    func append(_ data: Data) {
        guard data.count <= length else {
            delegate?.didFail(with: .bufferTooSmall, in: self)
            return
        }
        
        if data.beginsWithNaluStartCode {
            flush()
        }
        
        if data.count > length - endIndex {
            delegate?.didFail(with: .notEnoughSpace, in: self)
            endIndex = 0
        }
        
        data.copyBytes(to: buffer + endIndex, count: data.count)
        endIndex += data.count
        
        if data.endsWithZero {
            flush()
        }
    }
    
    func flush() {
        if endIndex > 0 {
            delegate?.didGatherUp(frame: bytes, in: self)
        }
        
        endIndex = 0
    }
}

extension Data {
    var beginsWithNaluStartCode: Bool {
        if count < 4 {
            return false
        }
        
        return self[0] == 0x00 && self[1] == 0x00 && self[2] == 0x00 && self[3] == 0x01
    }
    
    var endsWithZero: Bool {
        if let lastByte = last {
            return lastByte == 0x00
        }
        
        return false
    }
}
