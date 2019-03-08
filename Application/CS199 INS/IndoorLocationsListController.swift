//
//  IndoorLocationsListController.swift
//  CS199 INS
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import GRDB
import UIKit

class IndoorLocationsListController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = AppState.getBuilding().name
        //self.tabBarController?.tabBar.items![2].title = AppState.getBuilding().alias
        //self.tabBarItem.title = AppState.getBuilding().alias
        self.tableView.reloadData()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return AppState.getBuilding().floors
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (AppState.getBuilding().hasLGF) {
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
            default:
                return "Secret Floor" // Should never be the case
            }
        } else {
            switch section {
            case 0:
                return "Ground Floor"
            case 1:
                return "Second Floor"
            case 2:
                return "Third Floor"
            case 3:
                return "Fourth Floor"
            case 4:
                return "Fifth Floor"
            case 5:
                return "Sixth Floor"
            default:
                return "Secret Floor" // Should never be the case
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection floor: Int) -> Int {
        var locsCountInFloor : Int = 0
        do {
            try DB.write { db in
                locsCountInFloor = try IndoorLocation.filter(Column("bldg") == AppState.getBuilding().alias && Column("level") == floor + 1).fetchCount(db)
            }
        } catch {
            print(error)
        }
        return locsCountInFloor
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListRow", for: indexPath)
        cell.textLabel?.text = AppState.getBuildingLocs()[indexPath.section][indexPath.row].title
        cell.detailTextLabel?.text = AppState.getBuildingLocs()[indexPath.section][indexPath.row].subtitle
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppState.setNavSceneDestCoords(AppState.getBuildingLocs()[indexPath.section][indexPath.row].xcoord, AppState.getBuildingLocs()[indexPath.section][indexPath.row].ycoord)
        AppState.setDestinationLevel(AppState.getBuildingLocs()[indexPath.section][indexPath.row].level)
        // <NEW>
        // self.tabBarController!.switchTab(tabBarController: self.tabBarController!, to: self.tabBarController!.viewControllers![1])
        // </NEW>
        
        // Determine staircase/stairwell in building closest to destination
        if (!AppState.isUserOnDestinationLevel()) {
            var buildingStaircases = AppState.getBuildingStaircases()
            var navSceneDestCoords = AppState.getNavSceneDestCoords()
            var nearestStaircase : Staircase = buildingStaircases[0]
            var nearestStaircaseDistance : Double = sqrt(pow(navSceneDestCoords.x - nearestStaircase.xcoord, 2) + pow(navSceneDestCoords.y - nearestStaircase.ycoord, 2))
            //
            for staircase in buildingStaircases {
                var staircaseToDestDistance = sqrt(pow(navSceneDestCoords.x - staircase.xcoord, 2) + pow(navSceneDestCoords.y - staircase.ycoord, 2))
                if (staircaseToDestDistance <= nearestStaircaseDistance) {
                    nearestStaircase = staircase
                    nearestStaircaseDistance = staircaseToDestDistance
                }
            }
            //
            AppState.setNearestStaircase(nearestStaircase)
        }
        
        self.tabBarController!.tabBar.items![1].isEnabled = true
        self.tabBarController!.selectedIndex = 1
    }

}
