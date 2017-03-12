//
//  PacketsRecognitionTests.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 1/29/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import XCTest
@testable import WIFIAV

class PacketsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
    }
    
    // MARK: - Announcement tests
    
    func testAnnouncementIsRecognizedInBuffer() {
        let data = Data(bytes: announcementTestPacketBytes.ignoreUDPHeader())
        
        data.withUnsafeRawBufferPointer { buffer in
            XCTAssertTrue(Announcement.isRecognized(in: buffer))
        }
    }
    
    func testAnnouncementDidInitializeFromBuffer() {
        let data = Data(bytes: announcementTestPacketBytes.ignoreUDPHeader())
        
        data.withUnsafeRawBufferPointer { buffer in
            let announcement = try! Announcement(buffer)
            
            XCTAssertEqual(announcement.serverIp, "192.168.72.173")
            XCTAssertEqual(announcement.serviceName, "WIFICAM")
        }
    }
    
    // MARK: - AllInfoResponse tests
    
    func testAllInfoResponseIsRecognizedInBuffer() {
        let data = Data(bytes: allInfoResponseTestPacketBytes.ignoreUDPHeader())
    
        data.withUnsafeRawBufferPointer { buffer in
            XCTAssertTrue(AllInfoResponse.isRecognized(in: buffer))
        }
    }
    
    // MARK: - StreamSettingsResponse tests
    
    func testStreamSettingsResponseIsRecognizedInBuffer() {
        let data = Data(bytes: streamSettingsResponseTestPacketBytes.ignoreUDPHeader())
        
        data.withUnsafeRawBufferPointer { buffer in
            XCTAssertTrue(StreamSettingsResponse.isRecognized(in: buffer))
        }
    }
    
    // MARK: - Acknowledgement tests
    
    func testAcknowledgementIsRecognizedInBuffer() {
        let data = Data(bytes: acknowledgementTestPacketBytes.ignoreUDPHeader())
        
        data.withUnsafeRawBufferPointer { buffer in
            XCTAssertTrue(Acknowledgement.isRecognized(in: buffer))
        }
    }
    
    func testAcknowledgementDidInitializeFromBuffer() {
        let data = Data(bytes: acknowledgementTestPacketBytes.ignoreUDPHeader())
        
        data.withUnsafeRawBufferPointer { buffer in
            let acknowledgement = try! Acknowledgement(buffer)
            
            XCTAssertEqual(acknowledgement.received, 3)
            XCTAssertEqual(acknowledgement.next, 4)
        }
    }
    
    func testAcknowledgementDidSetProperBytesFromBuffer() {
        let data = Data(bytes: acknowledgementTestPacketBytes.ignoreUDPHeader())
        
        let expectedBytes = Data(bytes: [0x01, 0xff, 0x00, 0x76])
        
        data.withUnsafeRawBufferPointer { buffer in
            var acknowledgement = try! Acknowledgement(buffer)
            
            XCTAssertEqual(acknowledgement.received, 3)
            XCTAssertEqual(acknowledgement.next, 4)
            
            acknowledgement.received = 0xff
            acknowledgement.next = acknowledgement.received &+ 1
            
            XCTAssertEqual(acknowledgement.bytes, expectedBytes)
        }
    }
    
    func testAcknowledgementDidIitializeBytesFromArguments() {
        let expectedBytes = Data(bytes: [0x01, 0x01, 0x02, 0x76])
        
        let acknowledgement = Acknowledgement(received: 1, next: 2)
        
        XCTAssertEqual(acknowledgement.bytes, expectedBytes)
    }
    
    // MARK: - VideoData tests
    
    func testVideoDataIsRecognizedInBuffer() {
        let data = Data(bytes: videoDataTestPacketBytes.ignoreUDPHeader())
        
        data.withUnsafeRawBufferPointer { buffer in
            XCTAssertTrue(VideoData.isRecognized(in: buffer))
        }
    }
    
    func testVideoDataDidSetProperFieldsFromBuffer() {
        let data = Data(bytes: videoDataTestPacketBytes.ignoreUDPHeader())

        let expectedVideoData = Data(bytes: expectedVideoDataBytes)
        
        data.withUnsafeRawBufferPointer { buffer in
            let videoData = try! VideoData(buffer)
            
            XCTAssertEqual(videoData.sequence, 0x02)
            XCTAssertEqual(videoData.bytes, expectedVideoData)
        }
    }
}
