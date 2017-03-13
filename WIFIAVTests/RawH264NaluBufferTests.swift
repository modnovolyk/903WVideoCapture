//
//  RawH264BufferTests.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 2/1/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import XCTest
@testable import WIFIAV

class RawH264NaluBufferTests: XCTestCase {
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
        
        let buffer = RawH264NaluBuffer(length: 1024 * 20, delegate: delegate)
        
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
        let buffer = RawH264NaluBuffer(length: 1024 * 20)
        
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
        let buffer = RawH264NaluBuffer(length: 3000)
        
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
    typealias DidGatherUpHandler = (Data, NaluBuffer) -> Void
    typealias DidFailHandler = (NaluBufferError, NaluBuffer) -> Void
    
    var didGatherUp: DidGatherUpHandler?
    var didFail: DidFailHandler?
    
    init(didGatherUp: DidGatherUpHandler? = nil, didFail: DidFailHandler? = nil) {
        self.didGatherUp = didGatherUp
        self.didFail = didFail
    }
}

extension BufferDelegate: NaluBufferDelegate {
    func didGatherUp(frame: Data, in buffer: NaluBuffer) {
        didGatherUp?(frame, buffer)
    }
    
    func didFail(with error: NaluBufferError, in buffer: NaluBuffer) {
        didFail?(error, buffer)
    }
}
