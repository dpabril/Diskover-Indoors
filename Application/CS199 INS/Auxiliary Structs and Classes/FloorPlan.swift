//
//  FloorPlan.swift
//  CS199 INS
//
//  Created by Abril & Aquino on 09/02/2019.
//  Copyright © 2019 Abril & Aquino. All rights reserved.
//

import UIKit
import Foundation

struct FloorPlan {
    
    var floorLevel : Int
    var floorImage : UIImage
    
    init(_ floorLevel : Int, _ floorImage : UIImage) {
        self.floorLevel = floorLevel
        self.floorImage = floorImage
    }
    
}
