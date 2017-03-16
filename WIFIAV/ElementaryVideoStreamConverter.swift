//
//  ElementaryStreamConverter.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 2/2/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import AVFoundation

protocol VideoStreamConverter: class {
    var delegate: StreamConverterDelegate? { get set }
    
    init(delegate: StreamConverterDelegate?)
    
    func convert(frame: Data)
}

protocol StreamConverterDelegate: class {
    func didGatherUp(sample: CMSampleBuffer, in converter: VideoStreamConverter)
}

class ElementaryVideoStreamConverter: VideoStreamConverter {
    weak var delegate: StreamConverterDelegate?
    
    private var formatDescription: CMFormatDescription?
    
    required init(delegate: StreamConverterDelegate? = nil) {
        self.delegate = delegate
    }
    
    func convert(frame: Data) {
        guard frame.count > 4 else {
            return
        }
        
        func startCodeIndex(in data: Data, from: Data.Index = 0) -> Data.Index? {
            for i in from..<data.count - 5 {
                if frame[i] == 0x00 && frame[i + 1] == 0x00 && frame[i + 2] == 0x00 && frame[i + 3] == 0x01 {
                    return i
                }
            }
            
            return nil
        }
    
        var naluType = NALUnitType(rawValue: frame[4] & 0x1F) ?? .unspecified
        var spsRange: Range<Int>?
        var ppsRange: Range<Int>?
        
        if formatDescription == nil && naluType != .sps  {
            print("Error: formatDescription is nil and frame does not start from SPS")
            return
        }
        
        if naluType == .sps {
            guard let ppsSartIndex = startCodeIndex(in: frame, from: 4) else {
                print("Error: Can't find PPS start index")
                return
            }
    
            spsRange = 4..<ppsSartIndex
            naluType = NALUnitType(rawValue: frame[ppsSartIndex + 4] & 0x1F) ?? .unspecified
        }
        
        if naluType == .pps {
            guard let ppsStartIndex = spsRange?.upperBound,
                  let nextNaluPosition = startCodeIndex(in: frame, from: ppsStartIndex + 4) else {
                print("Error: Can't find next NALU after PPS to determine PPS length")
                return
            }
            
            ppsRange = ppsStartIndex + 4..<nextNaluPosition
            naluType = NALUnitType(rawValue: frame[nextNaluPosition + 4] & 0x1F) ?? .unspecified
        }
        
        if let spsRange = spsRange, let ppsRange = ppsRange {
            let spsSize = spsRange.upperBound - spsRange.lowerBound
            let ppsSize = ppsRange.upperBound - ppsRange.lowerBound
            
            let sps = UnsafeMutablePointer<UInt8>.allocate(capacity: spsSize)
            let pps = UnsafeMutablePointer<UInt8>.allocate(capacity: ppsSize)
            defer {
                sps.deallocate(capacity: spsSize)
                pps.deallocate(capacity: ppsSize)
            }
            
            frame.copyBytes(to: sps, from: spsRange)
            frame.copyBytes(to: pps, from: ppsRange)
            
            var parameterSetPointers: [UnsafePointer<UInt8>] = [UnsafePointer<UInt8>(sps), UnsafePointer<UInt8>(pps)]
            var parameterSetSizes: [Int] = [spsSize, ppsSize]
            
            formatDescription = nil
            
            let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                             2,
                                                                             &parameterSetPointers,
                                                                             &parameterSetSizes,
                                                                             4,
                                                                             &formatDescription)
            guard formatDescription != nil else {
                print("Error: Can't create CMFormatDescription (OSStatus: \(status))")
                return
            }
        }
        
        var blockBuffer: CMBlockBuffer?
        
        if naluType == .idr {
            guard let ppsRange = ppsRange else {
                print("Error: Can't determine start of IDR")
                return
            }
            
            let idrRange: Range<Int> = ppsRange.upperBound..<frame.count
            let idrSize = idrRange.upperBound - idrRange.lowerBound
            
            let idr = UnsafeMutablePointer<UInt8>.allocate(capacity: idrSize)
            defer {
                idr.deallocate(capacity: idrSize)
            }
            
            frame.copyBytes(to: idr, from: idrRange)
            
            idr.withMemoryRebound(to: UInt32.self, capacity: 1) { uint32Ptr in
                uint32Ptr.pointee = UInt32(idrSize - 4).bigEndian
            }
            
            guard CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                     idr, idrSize, kCFAllocatorNull,
                                                     nil, 0, idrSize, 0,
                                                     &blockBuffer) == kCMBlockBufferNoErr else {
                print("Error: Can't create CMBlockBuffer from IDR")
                return
            }
        }
        
        if naluType == .codedSlice {
            let codedSliceSize = frame.count
            
            let codedSlice = UnsafeMutablePointer<UInt8>.allocate(capacity: codedSliceSize)
            defer {
                codedSlice.deallocate(capacity: codedSliceSize)
            }
            
            frame.copyBytes(to: codedSlice, count: codedSliceSize)
            
            codedSlice.withMemoryRebound(to: UInt32.self, capacity: 1) { uint32Ptr in
                uint32Ptr.pointee = UInt32(codedSliceSize - 4).bigEndian
            }
            
            guard CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                     codedSlice, codedSliceSize, kCFAllocatorNull,
                                                     nil, 0, codedSliceSize, 0,
                                                     &blockBuffer) == kCMBlockBufferNoErr else {
                print("Error: Can't create CMBlockBuffer from coded slice")
                return
            }
        }
        
        guard blockBuffer != nil else {
            print("Error: Reached end of the method without available blockBuffer")
            return
        }
        
        var sampleSize = frame.count
        var sampleBuffer: CMSampleBuffer?
        
        guard CMSampleBufferCreate(kCFAllocatorDefault, blockBuffer, true, nil, nil,
                                   formatDescription, 1, 0, nil, 1, &sampleSize, &sampleBuffer) == noErr else {
            print("Error: Failed to create CMSampleBuffer")
            return
        }
        
        let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer!, true)
        let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
        let displayImmediatelyKey = Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque()
        let trueValue = Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
        CFDictionarySetValue(dictionary, displayImmediatelyKey, trueValue)
        
        delegate?.didGatherUp(sample: sampleBuffer!, in: self)
    }
}

extension ElementaryVideoStreamConverter: NaluBufferDelegate {
    func didGatherUp(frame: Data, in buffer: NaluBuffer) {
        convert(frame: frame)
    }
    
    func didFail(with error: NaluBufferError, in buffer: NaluBuffer) {
        print("NaluBuffer Error: \(error)")
    }
}
