//
//  QRTag.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import GRDB

class QRTag : Record {
    var url : String
    var xcoord : Double
    var ycoord : Double
    
    init(url: String, xcoord: Double, ycoord: Double) {
        self.url = url
        self.xcoord = xcoord
        self.ycoord = ycoord
        super.init()
    }
    
    override class var databaseTableName : String {
        return "QRTag"
    }
    
    enum Columns : String, ColumnExpression {
        case url, xcoord, ycoord
    }
    
    required init(row: Row) {
        url = row[Columns.url]
        xcoord = row[Columns.xcoord]
        ycoord = row[Columns.ycoord]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.url] = url
        container[Columns.xcoord] = xcoord
        container[Columns.ycoord] = ycoord
    }
}
