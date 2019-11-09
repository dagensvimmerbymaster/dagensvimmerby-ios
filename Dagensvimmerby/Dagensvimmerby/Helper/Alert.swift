//
//  Alert.swift
//  Dagensvimmerby
//
//  Created by Carlos Martin (SE) on 07/11/2016.
//  Copyright © 2016 TUVA Sweden AB. All rights reserved.
//

import Foundation
import UIKit

class Alert {
    static func showFailiureAlert(message: String, handler: (((UIAlertAction)?) -> Void)? = nil) {
        let alertTitle = message
        let alertButtonTitle = "OK"
        
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: alertButtonTitle, style: UIAlertAction.Style.default, handler: handler))
        
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(alert, animated: true, completion: nil)
        }
    }

}
