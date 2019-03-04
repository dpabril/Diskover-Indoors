//
//  Staircase.swift
//  CS199 INS
//
//  Created by Abril & Aquino on 04/03/2019.
//  Copyright © 2019 Abril & Aquino. All rights reserved.
//

import GRDB

class Staircase : Record {
    var bldg : String
    var xcoord : Double
    var ycoord : Double
    
    init(bldg: String, xcoord: Double, ycoord: Double) {
        self.bldg = bldg
        self.xcoord = xcoord
        self.ycoord = ycoord
        super.init()
    }
    
    override class var databaseTableName : String {
        return "Staircase"
    }
    
    enum Columns : String, ColumnExpression {
        case bldg, xcoord, ycoord
    }
    
    required init(row: Row) {
        bldg = row[Columns.bldg]
        xcoord = row[Columns.xcoord]
        ycoord = row[Columns.ycoord]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.bldg] = bldg
        container[Columns.xcoord] = xcoord
        container[Columns.ycoord] = ycoord
    }
}
