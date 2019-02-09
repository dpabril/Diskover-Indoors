//
//  IndoorLocation.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import GRDB

class IndoorLocation : Record {
    var bldg : String
    var level : Int
    var roomID : String
    var roomName : String?
    var xcoord : Double
    var ycoord : Double
    
    init(bldg: String, level: Int, roomID: String, roomName: String?, xcoord: Double, ycoord: Double) {
        self.bldg = bldg
        self.level = level
        self.roomID = roomID
        self.name = name
        self.xcoord = xcoord
        self.ycoord = ycoord
        super.init()
    }
    
    override class var databaseTableName : String {
        return "IndoorLocation"
    }
    
    enum Columns : String, ColumnExpression {
        case bldg, level, roomID, roomName, xcoord, ycoord
    }
    
    required init(row: Row) {
        bldg = row[Columns.bldg]
        level = row[Columns.level]
        roomID = row[Columns.roomID]
        roomName = row[Columns.roomName]
        xcoord = row[Columns.xcoord]
        ycoord = row[Columns.ycoord]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.bldg] = bldg
        container[Columns.level] = level
        container[Columns.roomID] = roomID
        container[Columns.roomName] = roomName
        container[Columns.xcoord] = xcoord
        container[Columns.ycoord] = ycoord
    }
}
