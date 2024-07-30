//
//  ClipboardApp.swift
//  Clipboard
//
//  Created by Luke Cai on 30/7/2024.
//

import Cocoa
import SwiftUI

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Perform any setup after launching the application.
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Perform any cleanup before terminating the application.
    }
}
