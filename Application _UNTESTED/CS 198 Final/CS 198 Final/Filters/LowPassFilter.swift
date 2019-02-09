//
//  LowPass.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 12/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import CoreMotion

class LowPassFilter {
    
    let kAccelerometerMinStep = 0.02
    let kAccelerometerNoiseAttenuation = 3.0
    
    var filterConstant : Double
    var adaptive : Bool
    var xAccel : Double
    var yAccel : Double
    var zAccel : Double
    
    init(rate : Double, cutoff : Double, adaptive : Bool) {
        let dt = 1.0 / rate
        let RC = 1.0 / cutoff
        
        self.filterConstant = dt / (dt + RC)
        self.adaptive = adaptive
        self.xAccel = 0
        self.yAccel = 0
        self.zAccel = 0
        
    }
    
    func norm(_ x : Double, _ y : Double, _ z : Double) -> Double {
        return sqrt(x * x + y * y + z * z)
    }
    
    func clamp(_ v : Double, _ min : Double, _ max : Double) -> Double {
        if (v > max) {
            return max
        } else if (v < min) {
            return min
        } else {
            return v
        }
    }
    
    func addAcceleration(_ accel : CMAcceleration) -> Void {
        var alpha = self.filterConstant
        
        if (self.adaptive) {
            let d = self.clamp(fabs(self.norm(self.xAccel, self.yAccel, self.zAccel) - self.norm(accel.x, accel.y, accel.z)) / self.kAccelerometerMinStep - 1.0, 0.0, 1.0)
            alpha = (1.0 - d) * self.filterConstant / self.kAccelerometerNoiseAttenuation + d * self.filterConstant
        }
        
        self.xAccel = accel.x * alpha + self.xAccel * (1.0 - alpha)
        self.yAccel = accel.y * alpha + self.yAccel * (1.0 - alpha)
        self.zAccel = accel.z * alpha + self.zAccel * (1.0 - alpha)
    }
    
    
}
