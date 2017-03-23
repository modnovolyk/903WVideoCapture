//
//  Protocols.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 3/23/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Foundation
import AVFoundation

// MARK: - Network Video Stream

protocol NetworkVideoStream: class {
    var delegate: NetworkVideoStreamDelegate? { get set }
    
    var socket: Socket { get set }
    var buffer: NaluBuffer { get set }
    var converter: VideoStreamConverter & NaluBufferDelegate { get set }
    
    init(socket: Socket, buffer: NaluBuffer, converter: VideoStreamConverter & NaluBufferDelegate, delegate: NetworkVideoStreamDelegate?)
    
    func process(_ data: Data)
}

protocol NetworkVideoStreamDelegate: class {
    func handle(sample: CMSampleBuffer, from stream: NetworkVideoStream)
}

// MARK: - Socket

protocol Socket: class {
    var delegate: SocketDelegate? { get set }
    var listening: Bool { get }
    
    init(port: Int, delegate: SocketDelegate?, queue: DispatchQueue) throws
    
    func listen()
    func send(_ data: Data, to address: sockaddr_in?) throws
    func shutdown()
}

protocol SocketDelegate: class {
    func didReceive(data: Data, from address: sockaddr_in, on socket: Socket)
}

// MARK: - NALU Buffer

protocol NaluBuffer: class {
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

// MARK: - Stream Converter

protocol VideoStreamConverter: class {
    var delegate: StreamConverterDelegate? { get set }
    
    init(delegate: StreamConverterDelegate?)
    
    func convert(frame: Data)
}

protocol StreamConverterDelegate: class {
    func didGatherUp(sample: CMSampleBuffer, in converter: VideoStreamConverter)
}
