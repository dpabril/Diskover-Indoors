//
//  SQLiteInterface.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import GRDB

class DBInterface {
    static func fetchQRTag(_ db : Database, url : String) -> QRTag? {
        var tag : QRTag?
        do {
            tag = try QRTag.fetchOne(db, "SELECT * FROM QRTag WHERE url = ?", arguments: [url])
            return tag
        } catch {
            return nil
        }
    }
    
    static func fetchBuilding(_ db : Database, alias : String) -> Building? {
        var building : Building?
        do {
            building = try Building.fetchOne(db, "SELECT * FROM Building WHERE alias = ?", arguments: [alias])
            return building
        } catch {
            return nil
        }
    }
    
    // CS 199, for GPS maybe?
    static func fetchAllBuildings(_ db: Database) -> [Building] {
        var buildings : [Building]
        do {
            buildings = try Building.fetchAll(db, "SELECT alias, name FROM Building")
            return buildings
        } catch {
            return []
        }
    }
    
    static func fetchFloor(_ db : Database, bldg : String, level : Int) -> Floor? {
        var floor : Floor?
        do {
            floor = try Floor.fetchOne(db, "SELECT * FROM Floor WHERE (bldg, level) = (?, ?)", arguments: [bldg, level])
            return floor
        } catch {
            return nil
        }
    }
    
    static func fetchFloors(_ db : Database, bldg : String) -> [Floor] {
        var floors : [Floor]
        do {
            floors = try Floor.fetchAll(db, "SELECT * FROM Floor WHERE bldg = ?", arguments: [bldg])
            return floors
        } catch {
            return []
        }
    }
    
    static func fetchIndoorLocation(_ db : Database, bldg : String, level : Int, name : String) -> IndoorLocation? {
        var loc : IndoorLocation?
        do {
            loc = try IndoorLocation.fetchOne(db, "SELECT * FROM IndoorLocation WHERE (bldg, level, name) = (?, ?, ?)", arguments: [bldg, level, name])
            return loc
        } catch {
            return nil
        }
    }
    
    static func fetchIndoorLocations(_ db : Database, bldg : String, level : Int) -> [IndoorLocation] {
        var locs : [IndoorLocation]
        do {
            locs = try IndoorLocation.fetchAll(db, "SELECT * FROM IndoorLocation WHERE (bldg, level) = (?, ?)", arguments: [bldg, level])
            return locs
        } catch {
            return []
        }
    }
}
