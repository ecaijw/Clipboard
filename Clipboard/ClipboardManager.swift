//
//  ClipboardManager.swift
//  Clipboard
//
//  Created by Luke Cai on 30/7/2024.
//
import AppKit
import Combine

class ClipboardManager: ObservableObject {
    @Published var history: [String] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var previousFocusedApp: NSRunningApplication?
    private let historyFileURL: URL
    
    init() {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportURL.appendingPathComponent("ClipboardApp")
        
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        self.historyFileURL = appDirectory.appendingPathComponent("clipboard_history.txt")
        
        loadHistory()
        startMonitoring()

        // Observe when the app becomes active
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        // Observe when the app becomes inactive
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidResignActive),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkClipboard), userInfo: nil, repeats: true)
    }
    
    @objc private func checkClipboard() {
        if let clipboardContent = NSPasteboard.general.string(forType: .string) {
            if NSPasteboard.general.changeCount != lastChangeCount {
                lastChangeCount = NSPasteboard.general.changeCount
                addClipboardContent(clipboardContent)
            }
        }
    }
    
    private func addClipboardContent(_ content: String) {
        if !history.contains(content) {
            history.insert(content, at: 0) // Add to the head of the history
            saveHistory()
        }
    }
    
    private func saveHistory() {
        do {
            var historyToSave = history
            if historyToSave.count > 100 {
                historyToSave = Array(historyToSave.prefix(100)) // Keep only the latest 100 entries
            }
            let jsonData = try JSONEncoder().encode(historyToSave)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try jsonString.write(to: historyFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Error saving history: \(error)")
        }
    }
    private func loadHistory() {
        do {
            let data = try Data(contentsOf: historyFileURL)
            history = try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Error loading history: \(error)")
        }
    }
    
    func pasteToClipboard(content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        pasteToPreviousApp()
    }
    
    @objc func appDidBecomeActive(notification: Notification) {
        // Save the previously focused application
        if let app = NSWorkspace.shared.frontmostApplication {
            print("The value of previousFocusedApp is: \(app)")

            let ignoredApps = ["luke.Clipboard"]
            if let bundleIdentifier = app.bundleIdentifier, ignoredApps.contains(bundleIdentifier) {
                print("Ignoring application: \(bundleIdentifier)")
                return
            }
            previousFocusedApp = app
        } else {
            print("The value of previousFocusedApp is: null")
        }
    }

    @objc func appDidResignActive(notification: Notification) {
        // Do nothing for now
    }

    private func pasteToPreviousApp() {
        guard let app = previousFocusedApp else { return }
        let scriptSource = """
            delay 5

            tell app "System Events"
                repeat 10 times
                    keystroke "#"
                end repeat
            end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptSource) {
            scriptObject.executeAndReturnError(&error)
        }
        
        if let error = error {
            print("Error: \(error)")
        } else {
            print("success")
        }
    }
    
    
    private func pasteToPreviousApp1() {
        // TODO
//        return
        guard let app = previousFocusedApp else { return }
        
        // Ensure the application is running
        guard app.isTerminated == false else {
            print("The previous focused application is not running.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            print("pasteToPreviousApp: \(app)")
            
            // Retry mechanism
            let maxRetries = 5
            var currentRetry = 0
            var success = false
            
            while currentRetry < maxRetries && !success {
                // Activate the application using NSRunningApplication
                DispatchQueue.main.async {
                    app.activate(options: [.activateAllWindows])
                }
                
                // Delay to ensure the app is activated
                usleep(500000) // 0.5 seconds delay

                let scriptSource = """
                tell application "System Events" to keystroke "v" using {command down}
                """
                
                var error: NSDictionary?
                if let scriptObject = NSAppleScript(source: scriptSource) {
                    scriptObject.executeAndReturnError(&error)
                }
                
                if let error = error {
                    print("Error: \(error)")
                    currentRetry += 1
                    usleep(500000) // sleep for 0.5 seconds before retrying
                } else {
                    success = true
                }
            }
            
            if !success {
                DispatchQueue.main.async {
                    print("Failed to activate application and paste after \(maxRetries) attempts")
                }
            }
        }
    }

    func pasteLastMinusOne() {
        guard history.count > 1 else { return }
        let lastMinusOne = history[1]
        history.insert(lastMinusOne, at: 0)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lastMinusOne, forType: .string)
    }
}
