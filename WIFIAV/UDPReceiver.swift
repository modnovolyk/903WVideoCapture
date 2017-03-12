//
//  UDPReceiver.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 1/24/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Darwin
import Dispatch
import Foundation

struct Socket {
    private let socket: Int32
    
    init() throws {
        self.socket = 0
    }
}

enum UDPSocketError: Error {
    case cantCreate
    case cantBind
}

protocol UDPReceiverDelegate: class {
    func didReceive(data: Data, on addr: sockaddr_in, from receiver: UDPReceiver)
}

class UDPReceiver {
    weak var delegate: UDPReceiverDelegate?
    
    private let internalBackgroundQueue = DispatchQueue(label: "udp_main_loop", qos: .background)
    private static let internalQueue = DispatchQueue(label: "UDPReceiver.internalQueue")
    private var _isReceiving = false
    private(set) var isReceiving: Bool {
        get {
            return UDPReceiver.internalQueue.sync {
                _isReceiving
            }
        }
        set {
            UDPReceiver.internalQueue.sync {
                _isReceiving = newValue
            }
        }
    }
    
    private let queue: DispatchQueue
    private let flagAccessQueue: DispatchQueue = DispatchQueue(label: "flagAccessQueue")
    private var socket: Int32
    
    init(port: Int, delegate: UDPReceiverDelegate? = nil, queue: DispatchQueue = DispatchQueue(label: "udp", qos: .background)) throws {
        self.queue = queue
        self.delegate = delegate
        
        socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socket != -1 else {
            throw UDPSocketError.cantCreate
        }
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = INADDR_ANY.bigEndian
        addr.sin_port = in_port_t(port).bigEndian
        
        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(socket, $0, socklen_t(MemoryLayout<sockaddr_in>.stride))
            }
        }
        
        guard result != -1 else {
            throw UDPSocketError.cantBind
        }
    }
    
    func start() {
        guard !isReceiving else {
            return
        }
        
        isReceiving = true
        
        internalBackgroundQueue.async { [unowned self] in
            var remaddr = sockaddr_in()
            var addrlen = socklen_t(MemoryLayout<sockaddr_in>.stride)
            
            let buflen = 2048
            let buf = UnsafeMutableRawPointer.allocate(bytes: buflen, alignedTo: 1)
            defer {
                buf.deallocate(bytes: buflen, alignedTo: 1)
            }
            
            repeat {
                let recsize = withUnsafePointer(to: &remaddr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        recvfrom(self.socket, buf, buflen, 0, UnsafeMutablePointer(mutating: $0), &addrlen)
                    }
                }
                
                //print(remaddr.sin_port.littleEndian)
                /*let recbuf = UnsafeMutableRawBufferPointer(start: buf, count: recsize)
                let recstring = String(bytes: recbuf, encoding: .ascii) ?? ""
                print("\(recsize): \(recstring)")*/
                
                if recsize != -1 {
                    self.queue.sync {
                        self.delegate?.didReceive(data: Data(bytes: buf, count: recsize), on: remaddr, from: self)
                    }
                }
            } while self.isReceiving
        }
    }
    
    func stop() {
        isReceiving = false
    }
    
    func send(to addr: sockaddr_in, data: Data) {
        var addr = addr
        let addrlen = socklen_t(MemoryLayout<sockaddr_in>.stride)
        data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
            let dataPrt = UnsafeRawPointer(bytes)
            let _ = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    sendto(socket, dataPrt, data.count, 0, $0, addrlen)
                }
            }
        }
    }
}
