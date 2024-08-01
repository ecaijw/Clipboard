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
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkClipboard), userInfo: nil, repeats: true)
        previousFocusedApp = NSWorkspace.shared.frontmostApplication
    }

    @objc private func checkClipboard() {
        previousFocusedApp = NSWorkspace.shared.frontmostApplication
        if let clipboardContent = NSPasteboard.general.string(forType: .string) {
            if NSPasteboard.general.changeCount != lastChangeCount {
                lastChangeCount = NSPasteboard.general.changeCount
                addClipboardContent(clipboardContent)
            }
        }
    }

    private func addClipboardContent(_ content: String) {
        if !history.contains(content) {
            history.append(content)
            saveHistory()
        }
    }

    private func saveHistory() {
        let historyString = history.joined(separator: "\n")
        try? historyString.write(to: historyFileURL, atomically: true, encoding: .utf8)
    }

    private func loadHistory() {
        if let historyString = try? String(contentsOf: historyFileURL, encoding: .utf8) {
            self.history = historyString.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
    }

    func pasteToClipboard(content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        pasteToPreviousApp()
    }

    private func pasteToPreviousApp() {
        // TODO
        return
        guard let app = previousFocusedApp else { return }

        let source = """
        tell application "\(app.bundleIdentifier!)"
            activate
            tell application "System Events" to keystroke "v" using command down
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: source) {
            scriptObject.executeAndReturnError(&error)
        }

        if let error = error {
            print("Error: \(error)")
        }
    }
}
