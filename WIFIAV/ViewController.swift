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

    lazy var videoStream: NetworkVideoStream = {
        let socket = try! UDPSocket(port: 3102, queue: DispatchQueue.main)
        let buffer = RawH264NaluBuffer(length: 1024 * 50)
        let converter: VideoStreamConverter & NaluBufferDelegate = ElementaryVideoStreamConverter()
        
        return W903NetworkVideoStream(socket: socket, buffer: buffer, converter: converter, delegate: self)
    }()
    
    lazy var videoLayer: AVSampleBufferDisplayLayer = {
        let layer = AVSampleBufferDisplayLayer()
        
        layer.frame = self.view.frame
        layer.bounds = self.view.bounds
        layer.backgroundColor = UIColor.black.cgColor
        
        return layer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        view.layer.addSublayer(videoLayer)
        
        _ = videoStream
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: NetworkVideoStreamDelegate {
    func handle(sample: CMSampleBuffer, from stream: NetworkVideoStream) {
        videoLayer.enqueue(sample)
    }
}
