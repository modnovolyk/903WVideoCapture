//
//  RawH264BufferTests.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 2/1/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import XCTest
@testable import WIFIAV

class RawH264BufferTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
    }
    
    func testBufferDidGatherUpFrame() {
        var receivedFrames = 0
        
        let delegate = BufferDelegate(didGatherUp: { frame, _ in
            XCTAssertGreaterThan(frame.count, 0)

            receivedFrames += 1
        })
        
        let buffer = RawH264Buffer(length: 1024 * 20)
        buffer.delegate = delegate
        
        for packetBytes in videoFramePackets {
            let packetData = Data(bytes: packetBytes.ignoreUDPHeader())
            let videoPacket = packetData.withUnsafeRawBufferPointer { buffer in
                return try! VideoData(buffer)
            }
            
            buffer.append(videoPacket.bytes)
        }
        
        XCTAssertEqual(receivedFrames, 1)
    }
    
    func testBufferDidReuseMemory() {
        let buffer = RawH264Buffer(length: 1024 * 20)
        
        for packetBytes in twoVideoFramesPackets {
            let packetData = Data(bytes: packetBytes.ignoreUDPHeader())
            let videoPacket = packetData.withUnsafeRawBufferPointer { buffer in
                return try! VideoData(buffer)
            }
            
            buffer.append(videoPacket.bytes)
        }
        
        XCTAssertEqual(buffer.endIndex, 0)
    }
    
    func testBufferDidHandleNotEnoughSpace() {
        let buffer = RawH264Buffer(length: 3000)
        
        let packetData = Data(bytes: videoFramePacket1.ignoreUDPHeader())
        let videoPacket = packetData.withUnsafeRawBufferPointer { buffer in
            return try! VideoData(buffer)
        }
        
        buffer.append(videoPacket.bytes)
        buffer.append(videoPacket.bytes)
        buffer.append(videoPacket.bytes)
        
        XCTAssertEqual(buffer.endIndex, videoPacket.bytes.count * 3)
        
        buffer.append(videoPacket.bytes)
        
        XCTAssertEqual(buffer.endIndex, videoPacket.bytes.count)
    }
}

class BufferDelegate {
    typealias DidGatherUpHandler = (Data, RawH264Buffer) -> Void
    typealias DidFailHandler = (RawH264BufferError, RawH264Buffer) -> Void
    
    var didGatherUp: DidGatherUpHandler?
    var didFail: DidFailHandler?
    
    init(didGatherUp: DidGatherUpHandler? = nil, didFail: DidFailHandler? = nil) {
        self.didGatherUp = didGatherUp
        self.didFail = didFail
    }
}

extension BufferDelegate: RawH264BufferDelegate {
    func didGatherUp(frame: Data, in buffer: RawH264Buffer) {
        didGatherUp?(frame, buffer)
    }
    
    func didFail(with error: RawH264BufferError, in buffer: RawH264Buffer) {
        didFail?(error, buffer)
    }
}
