//
//  MainTabBarController.swift
//  nfcond
//
//  Created by zhouziyu on 2025/11/12.
//

import UIKit
import SnapKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        tabBar.backgroundColor = .white
        tabBar.tintColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)
        tabBar.unselectedItemTintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        
        // 移除默认的顶部边框
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        

        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5)
        topBorder.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        tabBar.layer.addSublayer(topBorder)
    }
    
    private func setupViewControllers() {
        // 首页
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(systemName: "house.fill"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        // 卡包
        let cardPackVC = CardPackViewController()
        let cardPackNav = UINavigationController(rootViewController: cardPackVC)
        cardPackNav.tabBarItem = UITabBarItem(
            title: "卡包",
            image: UIImage(systemName: "wallet.pass.fill"),
            selectedImage: UIImage(systemName: "wallet.pass.fill")
        )
        
        // 记录
        let recordsVC = RecordsViewController()
        let recordsNav = UINavigationController(rootViewController: recordsVC)
        recordsNav.tabBarItem = UITabBarItem(
            title: "记录",
            image: UIImage(systemName: "list.bullet"),
            selectedImage: UIImage(systemName: "list.bullet")
        )
        
        // 设置
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "设置",
            image: UIImage(systemName: "gearshape.fill"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        
        viewControllers = [homeNav, cardPackNav, recordsNav, settingsNav]
    }
}

