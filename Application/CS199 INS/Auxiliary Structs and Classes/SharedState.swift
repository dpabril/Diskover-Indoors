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
    private var buildingCurrentFloor : FloorPlan?
    private var navSceneUserCoords : FloorPoint
    private var navSceneDestCoords : FloorPoint
    private var destinationLevel : FloorLevel?

    init() {
        self.hasScanned = false
        self.building = nil
        self.buildingLocs = []
        self.buildingFloorPlans = []
        self.buildingCurrentFloor = nil
        self.navSceneUserCoords = FloorPoint(0, 0)
        self.navSceneDestCoords = FloorPoint(0, 0)
        self.destinationLevel = nil
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
    func getBuildingCurrentFloor() -> FloorPlan {
        return self.buildingCurrentFloor!
    }
    func getNavSceneUserCoords() -> FloorPoint {
        return self.navSceneUserCoords
    }
    func getNavSceneDestCoords() -> FloorPoint {
        return self.navSceneDestCoords
    }
    func getDestinationLevel() -> FloorLevel {
        return self.destinationLevel!
    }

    // Setters
    func switchScanner() {
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
    func setBuildingCurrentFloor(_ buildingCurrentFloorLevel : Int) {
        self.buildingCurrentFloor = self.buildingFloorPlans[buildingCurrentFloorLevel - 1]
    }
    func setNavSceneUserCoords(_ navSceneUserXCoord : Double, _ navSceneUserYCoord : Double) {
        self.navSceneUserCoords = FloorPoint(navSceneUserXCoord, navSceneUserYCoord)
    }
    func setNavSceneDestCoords(_ navSceneDestXCoord : Double, _ navSceneDestYCoord : Double) {
        self.navSceneDestCoords = FloorPoint(navSceneDestXCoord, navSceneDestYCoord)
    }
    func setDestinationLevel(_ destinationLevel : Int){
        self.destinationLevel = FloorLevel(destinationLevel)
    }
}
