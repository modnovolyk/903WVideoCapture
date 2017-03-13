//
//  903WVideoStream.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 3/13/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Foundation
import AVFoundation

protocol NetworkVideoStream {
    var delegate: NetworkVideoStreamDelegate? { get set }
    
    var socket: Socket { get set }
    var buffer: NaluBuffer { get set }
    var converter: VideoStreamConverter & NaluBufferDelegate { get set }
    
    init(socket: Socket, buffer: NaluBuffer, converter: VideoStreamConverter & NaluBufferDelegate)
    
    func process(_ data: Data)
}

protocol NetworkVideoStreamDelegate: class {
    func handle(sample: CMSampleBuffer, from stream: NetworkVideoStream)
}

class W903NetworkVideoStream: NetworkVideoStream {
    weak var delegate: NetworkVideoStreamDelegate?
    var socket: Socket
    var buffer: NaluBuffer
    var converter: VideoStreamConverter & NaluBufferDelegate
    
    required init(socket: Socket = try! UDPSocket(port: 3102, queue: DispatchQueue.main),
                  buffer: NaluBuffer = RawH264NaluBuffer(length: 1024 * 50),
                  converter: VideoStreamConverter & NaluBufferDelegate = ElementaryVideoStreamConverter()) {
        self.socket = socket
        self.buffer = buffer
        self.converter = converter
        
        self.socket.delegate = self
        self.buffer.delegate = converter
        self.converter.delegate = self
    }
    
    deinit {
        socket.shutdown()
    }
    
    func process(_ data: Data) {
        
    }
}

extension W903NetworkVideoStream: SocketDelegate {
    func didReceive(data: Data, from address: sockaddr_in, on socket: Socket) {
        process(data)
    }
}

extension W903NetworkVideoStream: StreamConverterDelegate {
    func didGatherUp(sample: CMSampleBuffer, in converter: VideoStreamConverter) {
        delegate?.handle(sample: sample, from: self)
    }
}
