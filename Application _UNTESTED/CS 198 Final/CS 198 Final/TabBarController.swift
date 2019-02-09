//
//  TabBarController.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import UIKit

class TabBarController : UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        self.tabBar.items![1].isEnabled = false
        self.tabBar.items![2].isEnabled = false
    }

    // <NEW>
    override func tabBarController(_ tabBarController : UITabBarController, shouldSelect viewController : UIViewController) -> {
        switchTab(tabBarController: tabBarController, to: viewController)
        return true
    }

    func switchTab(tabBarController : UITabBarController, to viewController : UIViewController) {
        let currentView : UIView = tabBarController.selectedViewController!.view
        let targetView : UIView = viewController.view
        UIView.transition(from: currentView, to: targetView, duration: 0.3, options: [.curveEaseOut], completion: nil)
    }
    // </NEW>
}
