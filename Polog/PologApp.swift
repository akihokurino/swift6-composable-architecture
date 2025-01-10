//
//  PologApp.swift
//  Polog
//
//  Created by akiho on 2024/10/23.
//

import SwiftUI
import App

@main
struct PologApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
