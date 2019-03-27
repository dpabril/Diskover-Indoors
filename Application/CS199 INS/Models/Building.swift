//
//  Building.swift
//  CS199 INS
//
//  Created by Abril & Aquino on 11/12/2018.
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
