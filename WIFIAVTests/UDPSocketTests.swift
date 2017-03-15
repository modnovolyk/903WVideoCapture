//
//  UDPSocketTests.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 3/13/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import XCTest
@testable import WIFIAV

class UDPSocketTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
    }
    
    func testNotListeningSocketGetsDeallocatedImmediately() {
        var socket: UDPSocket? = try! UDPSocket(port: 55000)
        weak var weakSocket = socket
        
        XCTAssertNotNil(weakSocket)
        
        socket = nil
        
        XCTAssertNil(weakSocket)
    }
    
    func testListeningSocketGetsDeallocatedAfterShutdown() {
        weak var weakSocket: Socket?
        var socket: UDPSocket? = try! UDPSocket(port: 55001)
        weakSocket = socket
            
        socket?.listen()
            
        socket = nil
            
        XCTAssertNotNil(weakSocket)
            
        weakSocket?.shutdown()
        
        let nullifyExpectation = expectation(description: "Wait for socket shutdown")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(weakSocket)
            nullifyExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
}
