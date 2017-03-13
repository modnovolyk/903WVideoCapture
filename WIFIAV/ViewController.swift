//
//  ViewController.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 1/24/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    let receiver = try! UDPSocket(port: 3102, queue: DispatchQueue.main)
    let buffer = RawH264Buffer(length: 1024 * 50)
    let converter = StreamConverter()
    
    var state = ReceivingState.idle
    
    lazy var videoLayer: AVSampleBufferDisplayLayer = {
        let layer = AVSampleBufferDisplayLayer()
        
        layer.frame = self.view.frame
        layer.bounds = self.view.bounds
        //layer.videoGravity = AVLayerVideoGravityResizeAspect
        layer.backgroundColor = UIColor.black.cgColor
        
        return layer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        view.layer.addSublayer(videoLayer)
        
        buffer.delegate = converter
        converter.delegate = self
        
        receiver.delegate = self
        receiver.listen()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

enum ReceivingState {
    case idle
    case gotAnnouncement
    case gotAllInfo
    case gotStreamSettings
}

extension ViewController: SocketDelegate {
    func didReceive(data: Data, from addr: sockaddr_in, on socket: Socket) {
        data.withUnsafeBytes { (bytesPtr: UnsafePointer<UInt8>) -> Void in
            let bufferPointer = UnsafeRawBufferPointer(start: bytesPtr, count: data.count)
            
            switch state {
            case .idle where Announcement.isRecognized(in: bufferPointer):
                receiver.send(AllInfoRequest.bytes, to: addr)
                state = .gotAnnouncement
                
            case .gotAnnouncement where AllInfoResponse.isRecognized(in: bufferPointer):
                receiver.send(Acknowledgement(received: 0, next: 1).bytes, to: addr)
                receiver.send(StreamSettingsRequest.bytes, to: addr)
                state = .gotAllInfo
                
            case .gotAllInfo where StreamSettingsResponse.isRecognized(in: bufferPointer):
                receiver.send(Acknowledgement(received: 1, next: 2).bytes, to: addr)
                state = .gotStreamSettings
                
            case .gotStreamSettings where VideoData.isRecognized(in: bufferPointer):
                let videoData = try! VideoData(bufferPointer)
                receiver.send(Acknowledgement(received: videoData.sequence, next: videoData.sequence &+ 1).bytes, to: addr)
                buffer.append(videoData.bytes)
            
            case _ where Announcement.isRecognized(in: bufferPointer):
                //state = .idle
                break
                
            default:
                print("Default case")
            }
        }
    }
}

extension ViewController: StreamConverterDelegate {
    func didGatherUp(sample: CMSampleBuffer, in converter: StreamConverter) {
        videoLayer.enqueue(sample)
    }
}
