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
                return "Lower Ground Floor (LGF)"
            case 1:
                return "Ground Floor (GF)"
            case 2:
                return "Second Floor (2F)"
            case 3:
                return "Third Floor (3F)"
            case 4:
                return "Fourth Floor (4F)"
            case 5:
                return "Fifth Floor (5F)"
            default:
                return "" // Should never be the case
            }
        } else {
            switch section {
            case 0:
                return "Ground Floor (GF)"
            case 1:
                return "Second Floor (2F)"
            case 2:
                return "Third Floor (3F)"
            case 3:
                return "Fourth Floor (4F)"
            case 4:
                return "Fifth Floor (5F)"
            case 5:
                return "Sixth Floor (6F)"
            default:
                return "" // Should never be the case
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
        AppState.setDestinationTitle(AppState.getBuildingLocs()[indexPath.section][indexPath.row].title)
        AppState.setDestinationSubtitle(AppState.getBuildingLocs()[indexPath.section][indexPath.row].subtitle)
        // <NEW>
        // self.tabBarController!.switchTab(tabBarController: self.tabBarController!, to: self.tabBarController!.viewControllers![1])
        // </NEW>
        
        var buildingStaircases = AppState.getBuildingStaircases()
        var navSceneDestCoords = AppState.getNavSceneDestCoords()
        var nearestStaircase : Staircase = buildingStaircases[0]
        var nearestStaircaseDistance : Double = sqrt(pow(navSceneDestCoords.x - nearestStaircase.xcoord, 2) + pow(navSceneDestCoords.y - nearestStaircase.ycoord, 2))
        for staircase in buildingStaircases {
            var staircaseToDestDistance = sqrt(pow(navSceneDestCoords.x - staircase.xcoord, 2) + pow(navSceneDestCoords.y - staircase.ycoord, 2))
            if (staircaseToDestDistance <= nearestStaircaseDistance) {
                nearestStaircase = staircase
                nearestStaircaseDistance = staircaseToDestDistance
            }
        }
        AppState.setNearestStaircase(nearestStaircase)
        
        let message : String
        let locationHasSubtitle = AppState.getDestinationSubtitle().subtitle.count > 0
        if (locationHasSubtitle) {
            message = "\(AppState.getDestinationTitle().title)\n(\(AppState.getDestinationSubtitle().subtitle))"
        } else {
            message = "\(AppState.getDestinationTitle().title)"
        }
        
        let alertPrompt = UIAlertController(title: "This is your destination.", message: message, preferredStyle: .alert)
        
        let imageView = UIImageView(frame: CGRect(x: 25, y: locationHasSubtitle ? 100 : 80, width: 250, height: 333))
        imageView.image = UIImage(named: "\(AppState.getBuilding().alias)/\(AppState.getDestinationLevel().level)/\(AppState.getDestinationTitle().title)")
        if (imageView.image == nil) {
            imageView.image = UIImage(named: "ImgNotFound")
        }
        imageView.contentMode = .scaleAspectFit
        alertPrompt.view.addSubview(imageView)
        
        let height = NSLayoutConstraint(item: alertPrompt.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: locationHasSubtitle ? 485 : 465)
        alertPrompt.view.addConstraint(height)
        
        let width = NSLayoutConstraint(item: alertPrompt.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
        alertPrompt.view.addConstraint(width)
        
        let cancelAction = UIAlertAction(title: "Continue", style: UIAlertAction.Style.cancel, handler: {action in
            self.tabBarController!.tabBar.items![1].isEnabled = true
            self.tabBarController!.selectedIndex = 1
        })
        alertPrompt.addAction(cancelAction)
        
        self.present(alertPrompt, animated: true, completion: nil)
        
        //self.tabBarController!.tabBar.items![1].isEnabled = true
        //self.tabBarController!.selectedIndex = 1
    }

}
