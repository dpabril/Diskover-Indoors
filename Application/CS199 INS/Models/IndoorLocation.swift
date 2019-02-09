//
//  IndoorLocation.swift
//  CS199 INS
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import GRDB

class IndoorLocation : Record {
    var bldg : String
    var level : Int
    var title : String
    var subtitle : String
    var xcoord : Double
    var ycoord : Double
    
    init(bldg: String, level: Int, title: String, subtitle: String, xcoord: Double, ycoord: Double) {
        self.bldg = bldg
        self.level = level
        self.title = title
        self.subtitle = subtitle
        self.xcoord = xcoord
        self.ycoord = ycoord
        super.init()
    }
    
    override class var databaseTableName : String {
        return "IndoorLocation"
    }
    
    enum Columns : String, ColumnExpression {
        case bldg, level, title, subtitle, xcoord, ycoord
    }
    
    required init(row: Row) {
        bldg = row[Columns.bldg]
        level = row[Columns.level]
        title = row[Columns.title]
        subtitle = row[Columns.subtitle]
        xcoord = row[Columns.xcoord]
        ycoord = row[Columns.ycoord]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.bldg] = bldg
        container[Columns.level] = level
        container[Columns.title] = title
        container[Columns.subtitle] = subtitle
        container[Columns.xcoord] = xcoord
        container[Columns.ycoord] = ycoord
    }
}
