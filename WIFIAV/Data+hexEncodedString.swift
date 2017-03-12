//
//  Data+hexEncodedString.swift
//  WIFIAV
//
//  Created by Max Odnovolyk on 1/31/17.
//  Copyright © 2017 Max Odnovolyk. All rights reserved.
//

import Foundation

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
