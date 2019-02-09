//
//  Floor.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import GRDB

class Floor : Record {
    var bldg : String
    var level : Int
    
    init(bldg: String, level: Int) {
        self.bldg = bldg
        self.level = level
        super.init()
    }
    
    override class var databaseTableName : String {
        return "Floor"
    }
    
    enum Columns : String, ColumnExpression {
        case bldg, level
    }
    
    required init(row: Row) {
        bldg = row[Columns.bldg]
        level = row[Columns.level]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.bldg] = bldg
        container[Columns.level] = level
    }
}
