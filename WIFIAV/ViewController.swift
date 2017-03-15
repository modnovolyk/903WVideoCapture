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

    let videoStream: NetworkVideoStream = W903NetworkVideoStream()
    
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
        
        videoStream.delegate = self
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
