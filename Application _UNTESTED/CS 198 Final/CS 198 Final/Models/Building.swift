//
//  Building.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import GRDB

class Building : Record {
    var alias : String
    var name : String
    var floors : Int
    var hasLowerGroundFloor : Bool
    var delta : Double
    
    init(alias: String, name: String, floors: Int, hasLowerGroundFloor: Bool, delta: Double) {
        self.alias = alias
        self.name = name
        self.floors = floors
        self.hasLowerGroundFloor = hasLowerGroundFloor
        self.delta = delta
        super.init()
    }
    
    override class var databaseTableName : String {
        return "Building"
    }
    
    enum Columns : String, ColumnExpression {
        case alias, name, floors, hasLowerGroundFloor, delta
    }
    
    required init(row: Row) {
        alias = row[Columns.alias]
        name = row[Columns.name]
        floors = row[Columns.floors]
        hasLowerGroundFloor = row[Columns.hasLowerGroundFloor]
        delta = row[Columns.delta]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.alias] = alias
        container[Columns.name] = name
        container[Columns.floors] = floors
        container[Columns.hasLowerGroundFloor] = hasLowerGroundFloor
        container[Columns.delta] = delta
    }
}
