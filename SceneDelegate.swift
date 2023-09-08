//
//  SceneDelegate.swift
//  KRBeacon
//
//  Created by Dylan Carlyle on 4/09/23.
//  Copyright © 2023 SmudgeApps. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Configure your scene here.
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        // Set your root view controller here.
        window?.rootViewController = CameraViewController()
        window?.makeKeyAndVisible()
    }

    // Add other scene-related methods as needed.
}
