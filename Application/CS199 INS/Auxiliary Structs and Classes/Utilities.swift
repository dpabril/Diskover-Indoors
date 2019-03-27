//
//  Utilities.swift
//  CS199 INS
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
    
    static func radToDeg(_ radians : Double) -> Float {
        return Float(radians * 180 / .pi)
    }
    
    static func ordinalize(_ integer : Int, _ hasLGF : Bool) -> String {
        if (hasLGF) {
            switch integer {
            case 1:
                return "Lower Ground"
            case 2:
                return "Ground"
            case 3:
                return "2nd"
            case 4:
                return "3rd"
            case 5:
                return "4th"
            case 6:
                return "5th"
            default:
                // This should never be the case
                return ""
            }
        } else {
            switch integer {
            case 1:
                return "Ground"
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
                return ""
            }
        }
    }
    
    static func initializeSuccessMessage(_ level : Int, _ hasLGF : Bool, _ bldg : String) -> String {
        return String(format: "You are on the \(ordinalize(level, hasLGF)) Floor of \(bldg).")
    }
    
    static func currentLocationMessage(_ level : Int, _ hasLGF : Bool) -> String {
        return String(format: "You are on the \(ordinalize(level, hasLGF)) floor.")
    }
    
    static func targetLocationMessage(_ level : Int, _ hasLGF : Bool) -> String {
        return String(format: "Destination is on the \(ordinalize(level, hasLGF)) floor.")
    }
}
