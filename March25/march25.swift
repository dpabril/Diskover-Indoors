// <NEW> Additional variables in Building model to fit database schema
//
//  Building.swift
//  CS199 INS
//
//  Created by Abril & Aquino on 03/25/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import GRDB

class Building : Record {
    var alias : String
    var name : String
    var floors : Int
    var hasLGF : Bool
    var delta : Double
    var xscale : Double
    var yscale : Double
    var compassOffset : Double
    
    init(alias: String, name: String, floors: Int, hasLGF: Bool, delta: Double, xscale: Double, yscale: Double, compassOffset: Double) {
        self.alias = alias
        self.name = name
        self.floors = floors
        self.hasLGF = hasLGF
        self.delta = delta
        self.xscale = xscale
        self.yscale = yscale
        self.compassOffset = compassOffset
        super.init()
    }
    
    override class var databaseTableName : String {
        return "Building"
    }
    
    enum Columns : String, ColumnExpression {
        case alias, name, floors, hasLGF, delta, xscale, yscale, compassOffset
    }
    
    required init(row: Row) {
        alias = row[Columns.alias]
        name = row[Columns.name]
        floors = row[Columns.floors]
        hasLGF = row[Columns.hasLGF]
        delta = row[Columns.delta]
        xscale = row[Columns.xscale]
        yscale = row[Columns.yscale]
        compassOffset = row[Columns.compassOffset]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.alias] = alias
        container[Columns.name] = name
        container[Columns.floors] = floors
        container[Columns.hasLGF] = hasLGF
        container[Columns.delta] = delta
        container[Columns.xscale] = xscale
        container[Columns.yscale] = yscale
        container[Columns.compassOffset] = compassOffset
    }
}

// <NEW> in NavigationController.swift

override func viewWillAppear() {
    super.viewWillAppear(animated)
        
    let sceneFloor = self.scene.rootNode.childNode(withName: "Floor", recursively: true)!
    sceneFloor.geometry?.firstMaterial?.diffuse.contents = AppState.getBuildingCurrentFloor().floorImage
    let currentBuilding = AppState.getBuilding()
    sceneFloor.scale = SCNVector3(currentBuilding.xscale, currentBuilding.yscale, 1)
    let sceneFloorBoundaries = sceneFloor.boundingBox
    AppState.setFloorBoundaries(sceneFloorBoundaries.min.x, sceneFloorBoundaries.min.y, sceneFloorBoundaries.max.x, sceneFloorBoundaries.max.y)
    //
    // ...
    //

}

// <NEW> Auxiliary file: Constants.swift
enum Constants: Double {
    case userMarkerHeight = 0.0
    case targetMarkerHeight = 0.0
    case cameraHighestPoint = 0.0
    case cameraLowestPoint = 0.0
}

// <NEW> in SharedState.swift:
private var floorBoundaries: [CGPoint]

init() {
    self.floorBoundaries = []
}

func getFloorBoundaries() -> [CGPoint] {
    return self.floorBoundaries
}
func setFloorBoundaries(_ xmin: Double, _ ymin: Double, _ xmax: Double, _ ymax: Double) {
    self.floorBoundaries = [CGPoint(xmin, ymin), CGPoint(xmax, ymax)]
}

// <NEW> in NavigationController.swift: limiting panning/ motion
@IBAction func viewIsPanned(_ sender: UIPanGestureRecognizer) {
    var translation = sender.translation(in: self.navigationView)
    translation.x *= -1
    
    let camera = self.navigationView.pointOfView!
    camera.position = SCNVector3(camera.position.x + Float(translation.x / 1000), camera.position.y + Float(translation.y / 1000), camera.position.z)

    // let boundaries = AppState.getFloorBoundaries()
    // let isXBelowMinimum = camera.position <= boundaries[0].x
    // let isXAboveMaximum = camera.position >= boundaries[1].x
    // let isYBelowMinimum = camera.position <= boundaries[0].y
    // let isYAboveMaximum = camera.position >= boundaries[1].y
    // let isXUnsafe = isXBelowMinimum || isXAboveMaximum
    // let isYUnsafe = isYBelowMinimum || isYAboveMaximum

    // if (isXUnsafe) {
    //     if (isXBelowMinimum) {
    //         camera.position = SCNVector3(boundaries[0].x, camera.position.y, camera.position.z)
    //     } else if (isXAboveMaximum) {
    //         camera.position = SCNVector3(boundaries[1].x, camera.position.y, camera.position.z)
    //     }
    // }
    // if (isYUnsafe) {
    //     if (isYBelowMinimum) {
    //         camera.position = SCNVector3(camera.position.x, boundaries[0].y, camera.position.z)
    //     } else if (isYAboveMaximum) {
    //         camera.position = SCNVector3(camera.position.x, boundaries[1].y, camera.position.z)
    //     }
    // }
    self.limitTranslation(camera)

    sender.setTranslation(CGPoint.zero, in: self.navigationView)
}

func limitTranslation(object: SCNNode) {
    let boundaries = AppState.getFloorBoundaries()
    let isXBelowMinimum = object.position <= boundaries[0].x
    let isXAboveMaximum = object.position >= boundaries[1].x
    let isYBelowMinimum = object.position <= boundaries[0].y
    let isYAboveMaximum = object.position >= boundaries[1].y
    let isXUnsafe = isXBelowMinimum || isXAboveMaximum
    let isYUnsafe = isYBelowMinimum || isYAboveMaximum

    if (isXUnsafe) {
        if (isXBelowMinimum) {
            object.position.x = boundaries[0].x
        } else if (isXAboveMaximum) {
            object.position.x = boundaries[1].x
        }
    }
    if (isYUnsafe) {
        if (isYBelowMinimum) {
            object.position.y = boundaries[0].y
        } else if (isYAboveMaximum) {
            object.position.y = boundaries[1].y
        }
    }
}

// <NEW> in NavigationController.swift, in startDeviceMotionManager() for moving user (line 379)
self.limitTranslation(user)