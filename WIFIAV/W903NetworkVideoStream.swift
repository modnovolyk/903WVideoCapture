//
//  903WVideoStream.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 3/13/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Foundation
import AVFoundation

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

class W903NetworkVideoStream: NetworkVideoStream {
    weak var delegate: NetworkVideoStreamDelegate?
    
    var socket: Socket
    var buffer: NaluBuffer
    var converter: VideoStreamConverter & NaluBufferDelegate
    
    required init(socket: Socket = try! UDPSocket(port: 3102, queue: DispatchQueue.main),
                  buffer: NaluBuffer = RawH264NaluBuffer(length: 1024 * 50),
                  converter: VideoStreamConverter & NaluBufferDelegate = ElementaryVideoStreamConverter(),
                  delegate: NetworkVideoStreamDelegate? = nil) {
        self.socket = socket
        self.buffer = buffer
        self.converter = converter
        self.delegate = delegate
        
        socket.delegate = self
        buffer.delegate = converter
        converter.delegate = self
        
        socket.listen()
    }
    
    deinit {
        socket.shutdown()
    }
    
    enum ReceivingState {
        case idle
        case gotAnnouncement
        case gotAllInfo
        case gotStreamSettings
    }
    
    var state = ReceivingState.idle
    
    func process(_ data: Data) {
         data.withUnsafeBytes { (bytesPtr: UnsafePointer<UInt8>) -> Void in
             let bufferPointer = UnsafeRawBufferPointer(start: bytesPtr, count: data.count)
             
             switch state {
             case .idle where Announcement.isRecognized(in: bufferPointer):
                try! socket.send(Describe.bytes)
                state = .gotAnnouncement
             
             case .gotAnnouncement where Description.isRecognized(in: bufferPointer):
                try! socket.send(Acknowledgement(received: 0, next: 1))
                try! socket.send(SetUpStream.self)
                state = .gotAllInfo
             
             case .gotAllInfo where StreamSetUpAck.isRecognized(in: bufferPointer):
                try! socket.send(Acknowledgement(received: 1, next: 2).bytes)
                state = .gotStreamSettings
             
             case .gotStreamSettings where VideoData.isRecognized(in: bufferPointer):
                let videoData = try! VideoData(bufferPointer)
                try! socket.send(Acknowledgement(received: videoData.sequence, next: videoData.sequence &+ 1).bytes)
                buffer.append(videoData.bytes)
             
             case _ where Announcement.isRecognized(in: bufferPointer):
                state = .idle
             
             default:
                print("unhandled case")
             }
         }
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
