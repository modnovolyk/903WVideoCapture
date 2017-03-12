//
//  Packets.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 1/29/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Foundation

enum PacketError: Error {
    case invalidBufferSize
    case unrecognizedSignature
}

protocol IncomingPacket {
    static var size: Int { get }
    static func isRecognized(in buffer: UnsafeRawBufferPointer) -> Bool
    init(_ buffer: UnsafeRawBufferPointer) throws
}

protocol OutgoingPacket {
    var bytes: Data { get }
}

protocol StaticOutgoingPacket {
    static var bytes: Data { get }
}

struct Announcement: IncomingPacket {
    static let size = 32
    static let signature = UInt32(0x687a756c) /* luzh */
    
    let serverIp: String
    let serviceName: String
    
    static func isRecognized(in buffer: UnsafeRawBufferPointer) -> Bool {
        let sizeCheck = buffer.count == size
        let signatureCheck: () -> Bool = {
            buffer.load(as: UInt32.self) == signature
        }
        return sizeCheck && signatureCheck()
    }
    
    init(_ buffer: UnsafeRawBufferPointer) throws {
        guard buffer.count == Announcement.size else {
            throw PacketError.invalidBufferSize
        }
        
        guard Announcement.isRecognized(in: buffer) else {
            throw PacketError.unrecognizedSignature
        }
        
        let ipOffset = 4
        serverIp = "\(buffer.load(fromByteOffset: ipOffset + 0, as: UInt8.self))." +
                   "\(buffer.load(fromByteOffset: ipOffset + 1, as: UInt8.self))." +
                   "\(buffer.load(fromByteOffset: ipOffset + 2, as: UInt8.self))." +
                   "\(buffer.load(fromByteOffset: ipOffset + 3, as: UInt8.self))"

        var nameData = Data(buffer[8..<24])
        nameData.append(0)
        serviceName = nameData.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            String(cString: pointer)
        }
    }
}

struct AllInfoRequest: StaticOutgoingPacket {
    static var bytes: Data {
        return Data(bytes: [0x00, 0x00, 0x00, 0x76,         /*     ...v */
            0x30, 0x30, 0x31, 0x30, 0x30, 0x30, 0x30, 0x38, /* 00100008 */
            0x30, 0x30, 0x30, 0x30, 0x31, 0x30, 0x30, 0x37, /* 00001007 */
            0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x41, 0x6c, /* 000001Al */
            0x6c, 0x49, 0x6e, 0x66, 0x6f, 0x31])            /* lInfo1   */
    }
}

struct AllInfoResponse: IncomingPacket {
    static let size = 733
    static let signature = (0x00_6f_66_6e_49_6c_6c_41 as UInt64) /* AllInfo. */
    static let signatureOffset = 26
    
    static func isRecognized(in buffer: UnsafeRawBufferPointer) -> Bool {
        let sizeCheck = buffer.count == size

        let signatureCheck: () -> Bool = {
            let signaturePointer = (buffer.baseAddress! + signatureOffset)
                .bindMemory(to: UInt64.self, capacity: 1)
            return signaturePointer.pointee == signature
        }
        
        return sizeCheck && signatureCheck()
    }
    
    init(_ buffer: UnsafeRawBufferPointer) throws {
        guard buffer.count == AllInfoResponse.size else {
            throw PacketError.invalidBufferSize
        }
        
        guard AllInfoResponse.isRecognized(in: buffer) else {
            throw PacketError.unrecognizedSignature
        }
    }
}

struct StreamSettingsRequest: StaticOutgoingPacket {
    static var bytes: Data {
        return Data(bytes: [0x00, 0x01, 0x01, 0x76,         /*     ...v */
            0x30, 0x30, 0x31, 0x30, 0x30, 0x30, 0x30, 0x36, /* 00100006 */
            0x30, 0x30, 0x30, 0x30, 0x35, 0x38, 0x30, 0x35, /* 00005805 */
            0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x41, 0x75, /* 000001Au */
            0x64, 0x69, 0x6f, 0x31, 0x30, 0x35, 0x30, 0x30, /* dio10500 */
            0x30, 0x30, 0x30, 0x31, 0x56, 0x69, 0x64, 0x65, /* 0001Vide */
            0x6f, 0x31, 0x30, 0x39, 0x30, 0x30, 0x30, 0x30, /* o1090000 */
            0x30, 0x37, 0x46, 0x72, 0x61, 0x6d, 0x65, 0x53, /* 07FrameS */
            0x69, 0x7a, 0x65, 0x32, 0x38, 0x30, 0x30, 0x30, /* ize28000 */
            0x66, 0x30, 0x30, 0x39, 0x30, 0x30, 0x30, 0x30, /* f0090000 */
            0x30, 0x31, 0x46, 0x72, 0x61, 0x6d, 0x65, 0x52, /* 01FrameR */
            0x61, 0x74, 0x65, 0x66, 0x30, 0x37, 0x30, 0x30, /* atef0700 */
            0x30, 0x30, 0x30, 0x33, 0x42, 0x69, 0x74, 0x52, /* 0003BitR */
            0x61, 0x74, 0x65, 0x34, 0x30, 0x30])            /* ate400 */
    }
}

struct StreamSettingsResponse: IncomingPacket {
    static let size = 30
    static let signature = UInt32(0x31_74_65_52) /* Ret1 */
    static let signatureOffset = 26
    
    static func isRecognized(in buffer: UnsafeRawBufferPointer) -> Bool {
        let sizeCheck = buffer.count == size
        
        let signatureCheck: () -> Bool = {
            let signaturePointer = (buffer.baseAddress! + signatureOffset)
                .bindMemory(to: UInt32.self, capacity: 1)
            return signaturePointer.pointee == signature
        }
        
        return sizeCheck && signatureCheck()
    }
    
    init(_ buffer: UnsafeRawBufferPointer) throws {
        guard buffer.count == StreamSettingsResponse.size else {
            throw PacketError.invalidBufferSize
        }
        
        guard StreamSettingsResponse.isRecognized(in: buffer) else {
            throw PacketError.unrecognizedSignature
        }
    }
}

struct Acknowledgement: IncomingPacket, OutgoingPacket {
    static let size = 4
    static let headSignature = UInt8(0x01)
    static let tailSignature = UInt8(0x76)
    static let tailSignatureOffset = 3
    
    var received: UInt8
    var next: UInt8
    
    static func isRecognized(in buffer: UnsafeRawBufferPointer) -> Bool {
        let sizeCheck = buffer.count == 4
        
        let signatureCheck: () -> Bool = {
            let headSignatureCheck = buffer.load(as: UInt8.self) == headSignature
            let tailSignatureCheck = buffer.load(fromByteOffset: tailSignatureOffset,
                                                 as: UInt8.self) == tailSignature
            
            return headSignatureCheck && tailSignatureCheck
        }
        
        return sizeCheck && signatureCheck()
    }
    
    var bytes: Data {
        return Data(bytes: [Acknowledgement.headSignature,
                            received, next,
                            Acknowledgement.tailSignature])
    }
    
    init(_ buffer: UnsafeRawBufferPointer) throws {
        guard buffer.count == Acknowledgement.size else {
            throw PacketError.invalidBufferSize
        }
        
        guard Acknowledgement.isRecognized(in: buffer) else {
            throw PacketError.unrecognizedSignature
        }
        
        received = buffer.load(fromByteOffset: 1, as: UInt8.self)
        next = buffer.load(fromByteOffset: 2, as: UInt8.self)
    }
    
    init(received: UInt8, next: UInt8) {
        self.received = received
        self.next = next
    }
}

struct VideoData: IncomingPacket {
    static let size = signatureOffset + MemoryLayout.stride(ofValue: signature)
    static let signature = UInt32(0x61_74_61_44) /* Data */
    static let signatureOffset = 95
    static let sequenceOffset = 1
    
    static func isRecognized(in buffer: UnsafeRawBufferPointer) -> Bool {
        let sizeCheck = buffer.count >= size
        let signatureCheck: () -> Bool = {
            let signaturePointer = (buffer.baseAddress! + signatureOffset)
                .bindMemory(to: UInt32.self, capacity: 1)
            return signaturePointer.pointee == signature
        }
        return sizeCheck && signatureCheck()
    }
    
    let sequence: UInt8
    let bytes: Data
    
    init(_ buffer: UnsafeRawBufferPointer) throws {
        guard buffer.count >= VideoData.size else {
            throw PacketError.invalidBufferSize
        }
        
        guard VideoData.isRecognized(in: buffer) else {
            throw PacketError.unrecognizedSignature
        }
        
        self.sequence = buffer.load(fromByteOffset: VideoData.sequenceOffset, as: UInt8.self)
        self.bytes = Data(buffer.suffix(from: VideoData.size))
    }
}
