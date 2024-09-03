//
//  ClipboardApp.swift
//  Clipboard
//
//  Created by Luke Cai on 30/7/2024.
//

import SwiftUI
import MASShortcut
import Foundation

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class StatusBarView: NSView {
    private let imageView: NSImageView
    var action: Selector?
    weak var target: AnyObject?
    
    override init(frame frameRect: NSRect) {
        imageView = NSImageView(frame: frameRect)
        super.init(frame: frameRect)
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        imageView = NSImageView()
        super.init(coder: coder)
        addSubview(imageView)
    }
    
    var image: NSImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }
    
    override func mouseDown(with event: NSEvent) {
        if event.type == .leftMouseDown {
            // Handle left click
            if let action = self.action {
                NSApp.sendAction(action, to: self.target, from: self)
            }
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if event.type == .rightMouseDown {
            // Handle right click
            if let menu = self.menu {
                NSMenu.popUpContextMenu(menu, with: event, for: self)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    var popoverTransiencyMonitor: Any?
    @ObservedObject var clipboardManager = ClipboardManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            let statusBarView = StatusBarView(frame: button.bounds)
            statusBarView.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
            statusBarView.target = self
            statusBarView.action = #selector(leftClick(_:))
            statusBarView.menu = constructMenu() // Assign the menu here
            button.addSubview(statusBarView)
        }
        
        popover.contentViewController = NSHostingController(rootView: ContentView(clipboardManager: clipboardManager))
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
    

    @objc func leftClick(_ sender: NSStatusBarButton) {
        togglePopover(sender)
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

    func constructMenu() -> NSMenu {
        let menu = NSMenu()

        // Quit menu item
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        // Paste Last - 1 menu item
        menu.addItem(NSMenuItem(title: "Paste Last - 1", action: #selector(pasteLastMinusOne), keyEquivalent: "p"))

        // About menu item
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "a"))

        return menu
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }

    @objc func pasteLastMinusOne() {
        clipboardManager.pasteLastMinusOne()
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "About"
        alert.informativeText = "Clipboard Assistant V1.0 \n\nManage your clipboard history.\nClick a history item to copy it."
        alert.runModal()
    }

    func adjustPopoverPosition() {
        guard let popoverWindow = popover.contentViewController?.view.window else {
            return
        }

        var popoverFrame = popoverWindow.frame
        popoverFrame.origin.y -= 110  // Move the popover down by 150 pixels
        popoverWindow.setFrame(popoverFrame, display: true, animate: true)
    }
}
