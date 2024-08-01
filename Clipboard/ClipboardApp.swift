//
//  ClipboardApp.swift
//  Clipboard
//
//  Created by Luke Cai on 30/7/2024.
//

import SwiftUI
import MASShortcut

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    var popoverTransiencyMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
            button.action = #selector(togglePopover(_:))
        }
        
        popover.contentViewController = NSHostingController(rootView: ContentView())
        popover.behavior = .transient

        // Monitor for clicks outside of the popover to close it
        popoverTransiencyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.popover.performClose(event)
        }

        // Register global shortcut (Cmd + Shift + V)
        let shortcut = MASShortcut(keyCode: kVK_ANSI_V, modifierFlags: [.command, .shift])
        MASShortcutMonitor.shared().register(shortcut, withAction: { [weak self] in
            self?.togglePopover(nil)
        })
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                adjustPopoverPosition()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func adjustPopoverPosition() {
        guard let popoverWindow = popover.contentViewController?.view.window else {
            return
        }

        var popoverFrame = popoverWindow.frame
        popoverFrame.origin.y -= 150  // Move the popover down by 150 pixels
        popoverWindow.setFrame(popoverFrame, display: true, animate: true)
    }
}
