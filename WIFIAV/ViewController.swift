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

    let receiver = try! UDPReceiver(port: 3102, queue: DispatchQueue.main)
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
        receiver.start()
        
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

extension ViewController: UDPReceiverDelegate {
    func didReceive(data: Data, on addr: sockaddr_in, from receiver: UDPReceiver) {
        data.withUnsafeBytes { (bytesPtr: UnsafePointer<UInt8>) -> Void in
            let bufferPointer = UnsafeRawBufferPointer(start: bytesPtr, count: data.count)
            
            switch state {
            case .idle where Announcement.isRecognized(in: bufferPointer):
                receiver.send(to: addr, data: AllInfoRequest.bytes)
                state = .gotAnnouncement
                
            case .gotAnnouncement where AllInfoResponse.isRecognized(in: bufferPointer):
                receiver.send(to: addr, data: Acknowledgement(received: 0, next: 1).bytes)
                receiver.send(to: addr, data: StreamSettingsRequest.bytes)
                state = .gotAllInfo
                
            case .gotAllInfo where StreamSettingsResponse.isRecognized(in: bufferPointer):
                receiver.send(to: addr, data: Acknowledgement(received: 1, next: 2).bytes)
                state = .gotStreamSettings
                
            case .gotStreamSettings where VideoData.isRecognized(in: bufferPointer):
                let videoData = try! VideoData(bufferPointer)
                receiver.send(to: addr, data: Acknowledgement(received: videoData.sequence, next: videoData.sequence &+ 1).bytes)
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
