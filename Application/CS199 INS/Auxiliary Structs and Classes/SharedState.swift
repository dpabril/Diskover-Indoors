//
//  SharedState.swift
//  CS 199
//
//  Created by Abril & Aquino on 2/2/2018.
//  Copyright © 2019 Abril & Aquino. All rights reserved.
//

import UIKit

class SharedState {
    
    private var hasScanned : Bool
    
    private var currentBuilding : Building?
    private var currentBuildingLocs : [[IndoorLocation]]
    private var currentFloorPlanImage : UIImage?
    private var navSceneXCoord : Double
    private var navSceneYCoord : Double

    init() {
        self.hasScanned = false
        self.currentBuilding = nil
        self.currentBuildingLocs = []
        self.currentFloorPlanImage = nil
        self.navSceneXCoord = 0
        self.navSceneYCoord = 0
    }

    // Getters
    func userHasScanned() -> Bool {
        return self.hasScanned
    }
    func getCurrentBuilding() -> Building {
        return self.currentBuilding!
    }
    func getCurrentBuildingLocs() -> [[IndoorLocation]] {
        return self.currentBuildingLocs
    }
    func getCurrentFloorPlanImage() -> UIImage {
        return self.currentFloorPlanImage!
    }
    func getNavSceneXCoord() -> Double {
        return self.navSceneXCoord
    }
    func getNavSceneYCoord() -> Double {
        return self.navSceneYCoord
    }

    // Setters
    func switchHasScanned() {
        if (self.hasScanned) {
            self.hasScanned = false
        } else {
            self.hasScanned = true
        }
    }
    func setCurrentBuilding(_ currentBuilding : Building) {
        self.currentBuilding = currentBuilding
    }
    func setCurrentBuildingLocs(_ currentBuildingLocs : [[IndoorLocation]]) {
        self.currentBuildingLocs = currentBuildingLocs
    }
    func setCurrentFloorPlanImage(_ currentFloorPlanImage : UIImage) {
        self.currentFloorPlanImage = currentFloorPlanImage
    }
    func setNavSceneXCoord(_ navSceneXCoord : Double) {
        self.navSceneXCoord = navSceneXCoord
    }
    func setNavSceneYCoord(_ navSceneYCoord : Double) {
        self.navSceneYCoord = navSceneYCoord
    }
}
