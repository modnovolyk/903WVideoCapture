//
//  UDPSocket.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 1/24/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Darwin
import Dispatch
import Foundation

protocol Socket {
    var delegate: SocketDelegate? { get set }
    var listening: Bool { get }
    
    init(port: Int, delegate: SocketDelegate?, queue: DispatchQueue) throws
    
    func listen()
    func stopListening()
    func send(_ data: Data, to addr: sockaddr_in?)
}

protocol SocketDelegate: class {
    func didReceive(data: Data, from addr: sockaddr_in, on socket: Socket)
}

enum SocketError: Error {
    case cantCreate
    case cantBind
}

class UDPSocket: Socket {
    weak var delegate: SocketDelegate?
    
    private(set) var listening: Bool {
        get {
            return serialQueue.sync {
                _listening
            }
        }
        set {
            serialQueue.sync {
                _listening = newValue
            }
        }
    }
    
    private var _listening = false
    
    private let serialQueue = DispatchQueue(label: "UDPSocket.serialQueue")
    private let backgroundQueue = DispatchQueue(label: "UDPSocket.backgroundQueue(receiving-loop)", qos: .background)
    private let delegationQueue: DispatchQueue
    
    private var socket: Int32
    
    required init(port: Int, delegate: SocketDelegate? = nil, queue: DispatchQueue = DispatchQueue(label: "udp", qos: .background)) throws {
        self.delegationQueue = queue
        self.delegate = delegate
        
        socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socket != -1 else {
            throw SocketError.cantCreate
        }
        
        var socketAddress = sockaddr_in()
        socketAddress.sin_family = sa_family_t(AF_INET)
        socketAddress.sin_addr.s_addr = INADDR_ANY.bigEndian
        socketAddress.sin_port = in_port_t(port).bigEndian
        
        let bindResult = withUnsafePointer(to: &socketAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                return bind(socket, $0, socklen_t(MemoryLayout<sockaddr_in>.stride))
            }
        }
        
        guard bindResult != -1 else {
            throw SocketError.cantBind
        }
    }
    
    func listen() {
        guard !listening else {
            return
        }
        
        listening = true
        
        backgroundQueue.async { [unowned self] in
            var sourceAddress = sockaddr_in()
            var addressLength = socklen_t(MemoryLayout<sockaddr_in>.stride)
            
            let bufferLength = 2048
            let buffer = UnsafeMutableRawPointer.allocate(bytes: bufferLength, alignedTo: 1)
            defer {
                buffer.deallocate(bytes: bufferLength, alignedTo: 1)
            }
            
            repeat {
                let receivedLength = withUnsafePointer(to: &sourceAddress) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        return recvfrom(self.socket, buffer, bufferLength, 0, UnsafeMutablePointer(mutating: $0), &addressLength)
                    }
                }
                
                if receivedLength > 0 {
                    self.delegationQueue.async {
                        self.delegate?.didReceive(data: Data(bytes: buffer, count: receivedLength), from: sourceAddress, on: self)
                    }
                }
            } while self.listening
        }
    }
    
    func stopListening() {
        listening = false
    }
    
    func send(_ data: Data, to addr: sockaddr_in? = nil) {
        var addr = addr
        let addrlen = socklen_t(MemoryLayout<sockaddr_in>.stride)
        data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
            let dataPrt = UnsafeRawPointer(bytes)
            let _ = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    return sendto(socket, dataPrt, data.count, MSG_DONTWAIT, $0, addrlen)
                }
            }
        }
    }
    
    deinit {
        // Deal with running receiving loop
        
        close(socket)
    }
}
