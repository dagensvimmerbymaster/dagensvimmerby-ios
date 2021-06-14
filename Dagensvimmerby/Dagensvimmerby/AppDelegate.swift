//
//  AppDelegate.swift
//  Dagensvimmerby
//
//  Created by Carlos Martin (SE) on 25/10/2016.
//  Copyright © 2016 TUVA Sweden AB. All rights reserved.
//

import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    
    let parseConfig = ParseClientConfiguration { (ParseMutableClientConfiguration) in
        ParseMutableClientConfiguration.applicationId = Bundle.main.infoDictionary!["PARSE_APPID"] as? String
        ParseMutableClientConfiguration.server = Bundle.main.infoDictionary!["PARSE_SERVERID"] as! String
    }
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //push notification settings
        let userNotificationTypes: UIUserNotificationType = [.alert, .badge, .sound]
        let settings = UIUserNotificationSettings(types: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        //parse settings
        Parse.enableLocalDatastore()
        Parse.initialize(with: self.parseConfig)
        
        //print(isDevelopmentEnvironment().description ?? "none")
        
        return true
    }
    
    func isDevelopmentEnvironment() -> Bool {
        guard let filePath = Bundle.main.path(forResource: "embedded", ofType:"mobileprovision") else {
            return false
        }
        do {
            let url = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: url)
            guard let string = String(data: data, encoding: .ascii) else {
                return false
            }
            if string.contains("<key>aps-environment</key>\n\t\t<string>development</string>") {
                return true
            }
        } catch {}
        return false
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let installation = PFInstallation.current() {
            installation.setDeviceTokenFrom(deviceToken)
            installation.saveInBackground()
        } else {
            print("PFInstallation.saveInBackgroupd problems!")
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        PFPush.handle(userInfo)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0
        if let installation = PFInstallation.current() {
            installation.badge = 0
            installation.saveInBackground()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

