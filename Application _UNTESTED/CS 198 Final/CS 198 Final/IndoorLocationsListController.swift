//
//  IndoorLocationsListController.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import UIKit

class IndoorLocationsListController: UITableViewController {
    
    var roomList : [IndoorLocation] = []
    // <NEW>
    var currentBuilding : Building?
    // </NEW>

    var xCoord : Double = 0
    var yCoord : Double = 0
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.roomList = (self.tabBarController!.viewControllers![0] as! QRCodeScannerController).locs
        self.tableView.reloadData()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
        // <NEW>
        return (currentBuilding?.floors)!
        // </NEW>
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection floorNumber: Int) -> Int {
        return roomList.count
        // <NEW>
        do {
            var locsCountInFloor : Int
            try DB.write { db in
                if currentBuilding.hasLowerGroundFloor == true {
                    locsCountInFloor = IndoorLocation.filter(bldg == currentBuilding && level == floorNumber).fetchCount(db)
                } else {
                    locsCountInFloor = IndoorLocation.filter(bldg == currentBuilding && level == floorNumber + 1).fetchCount(db)
                }
                return locsCountInFloor
            }
        } catch {
            return 0
        }
        // </NEW>
    }
    
    // <NEW>
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (currentBuilding.hasLowerGroundFloor == true) {
            switch section {
            case 0:
                return "Lower Ground Floor"
            case 1:
                return "Upper Ground Floor"
            case 2:
                return "Second Floor"
            case 3:
                return "Third Floor"
            case 4:
                return "Fourth Floor"
            case 5:
                return "Fifth Floor"
            }
        } else {
            switch section {
            case 0:
                return "Ground Floor"
            case 1:
                return "Second Floor"
            case 2:
                return "Thirds Floor"
            case 3:
                return "Fourth Floor"
            case 4:
                return "Fifth Floor"
            case 5:
                return "Sixth Floor"
            }
        }
    }
    // </NEW>

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListRow", for: indexPath)
        cell.textLabel?.text = roomList[indexPath.row].title
        // <NEW>
        // set cell type to 'subtitle' in Interface Builder
        cell.detailTextLabel?.text = roomList[indexPath.row].subtitle
        // </NEW>
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.xCoord = roomList[indexPath.row].xcoord
        self.yCoord = roomList[indexPath.row].ycoord
        // <NEW>
        self.tabBarController!.switchTab(tabBarController: self.tabBarController!, to: self.tabBarController!.viewControllers![1])
        // </NEW>
        self.tabBarController!.selectedIndex = 1
    }
}
