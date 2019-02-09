//
//  Utilities.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 12/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import Foundation

class Utilities {
    static func QRFragments(_ QRMetadata : String) -> [String] {
        return QRMetadata.components(separatedBy: "::")
    }
    
    static func degToRad(_ degrees : Double) -> Float {
        return Float(degrees * .pi / 180)
    }
    
    static func ordinalize(_ integer : Int) -> String {
        switch integer {
        case 0:
            return "basement"
        case 1:
            return "ground"
        case 2:
            return "2nd"
        case 3:
            return "3rd"
        case 4:
            return "4th"
        case 5:
            return "5th"
        default:
            // This should never be the case
            return "magic"
        }
    }
    
    static func localizeSuccessMessage(_ bldg : String, _ level : Int) -> String {
        return String(format: "You are on the %s floor of %s.", ordinalize(level), bldg)
    }
    
    static func currentLocationMessage(_ level : Int) -> String {
        return String(format: "You are on the %s floor.", ordinalize(level))
    }
    
    static func targetLocationMessage(_ level : Int) -> String {
        return String(format: "Destination is on the %s floor.", ordinalize(level))
    }
}
