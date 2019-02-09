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
    
    private var building : Building?
    private var buildingLocs : [[IndoorLocation]]
    private var buildingFloorPlans : [FloorPlan]
    private var buildingSelectedFloorPlan : FloorPlan?
    private var navSceneXCoord : Double
    private var navSceneYCoord : Double

    init() {
        self.hasScanned = false
        self.building = nil
        self.buildingLocs = []
        self.buildingFloorPlans = []
        self.buildingSelectedFloorPlan = nil
        self.navSceneXCoord = 0
        self.navSceneYCoord = 0
    }

    // Getters
    func userHasScanned() -> Bool {
        return self.hasScanned
    }
    func getBuilding() -> Building {
        return self.building!
    }
    func getBuildingLocs() -> [[IndoorLocation]] {
        return self.buildingLocs
    }
    func getBuildingFloorPlans() -> [FloorPlan] {
        return self.buildingFloorPlans
    }
    func getBuildingSelectedFloorPlan() -> FloorPlan {
        return self.buildingSelectedFloorPlan!
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
    func setBuilding(_ building : Building) {
        self.building = building
    }
    func setBuildingLocs(_ buildingLocs : [[IndoorLocation]]) {
        self.buildingLocs = buildingLocs
    }
    func setBuildingFloorPlans(_ buildingFloorPlans : [FloorPlan]) {
        self.buildingFloorPlans = buildingFloorPlans
    }
    func setBuildingSelectedFloorPlan(_ buildingSelectedFloorPlan : FloorPlan) {
        self.buildingSelectedFloorPlan = buildingSelectedFloorPlan
    }
    func setNavSceneXCoord(_ navSceneXCoord : Double) {
        self.navSceneXCoord = navSceneXCoord
    }
    func setNavSceneYCoord(_ navSceneYCoord : Double) {
        self.navSceneYCoord = navSceneYCoord
    }
}
