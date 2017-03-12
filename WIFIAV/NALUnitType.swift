//
//  NALUnitType.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 2/2/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Foundation

enum NALUnitType: UInt8, CustomStringConvertible {
    case unspecified = 0
    case codedSlice = 1
    case dataPartitionA = 2
    case dataPartitionB = 3
    case dataPartitionC = 4
    case idr = 5
    case sei = 6
    case sps = 7
    case pps = 8
    case accessUnitDelimiter = 9
    case endOfSequence = 10
    case endOfStream = 11
    case filterData = 12
    case spsExtension = 13
    case prefixNALU = 14
    case subsetSPS = 15
    case reserved16 = 16
    case reserved17 = 17
    case reserved18 = 18
    case csaPictureWoPartitioning = 19
    case cse = 20
    case cseDepthView = 21
    case reserved22 = 22
    case reserved23 = 23
    case stapa = 24
    case stapb = 25
    case mtap16 = 26
    case mtap24 = 27
    case fua = 28
    case fub = 29
    case unspecified30 = 30
    case unspecified31 = 31
    
    var description: String {
        switch self {
        case .unspecified:
            return "0: Unspecified (non-VCL)"
        case .codedSlice:
            return "1: Coded slice of a non-IDR picture (VCL)"
        case .dataPartitionA:
            return "2: Coded slice data partition A (VCL)"
        case .dataPartitionB:
            return "3: Coded slice data partition B (VCL)"
        case .dataPartitionC:
            return "4: Coded slice data partition C (VCL)"
        case .idr:
            return "5: Coded slice of an IDR picture (VCL)"
        case .sei:
            return "6: Supplemental enhancement information (SEI) (non-VCL)"
        case .sps:
            return "7: Sequence parameter set (non-VCL)"
        case .pps:
            return "8: Picture parameter set (non-VCL)"
        case .accessUnitDelimiter:
            return "9: Access unit delimiter (non-VCL)"
        case .endOfSequence:
            return "10: End of sequence (non-VCL)"
        case .endOfStream:
            return "11: End of stream (non-VCL)"
        case .filterData:
            return "12: Filler data (non-VCL)"
        case .spsExtension:
            return "13: Sequence parameter set extension (non-VCL)"
        case .prefixNALU:
            return "14: Prefix NAL unit (non-VCL)"
        case .subsetSPS:
            return "15: Subset sequence parameter set (non-VCL)"
        case .reserved16:
            return "16: Reserved (non-VCL)"
        case .reserved17:
            return "17: Reserved (non-VCL)"
        case .reserved18:
            return "18: Reserved (non-VCL)"
        case .csaPictureWoPartitioning:
            return "19: Coded slice of an auxiliary coded picture without partitioning (non-VCL)"
        case .cse:
            return "20: Coded slice extension (non-VCL)"
        case .cseDepthView:
            return "21: Coded slice extension for depth view components (non-VCL)"
        case .reserved22:
            return "22: Reserved (non-VCL)"
        case .reserved23:
            return "23: Reserved (non-VCL)"
        case .stapa:
            return "24: STAP-A Single-time aggregation packet (non-VCL)"
        case .stapb:
            return "25: STAP-B Single-time aggregation packet (non-VCL)"
        case .mtap16:
            return "26: MTAP16 Multi-time aggregation packet (non-VCL)"
        case .mtap24:
            return "27: MTAP24 Multi-time aggregation packet (non-VCL)"
        case .fua:
            return "28: FU-A Fragmentation unit (non-VCL)"
        case .fub:
            return "29: FU-B Fragmentation unit (non-VCL)"
        case .unspecified30:
            return "30: Unspecified (non-VCL)"
        case .unspecified31:
            return "31: Unspecified (non-VCL)"
        }
    }
}
