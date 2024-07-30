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

    init() {
        startMonitoring()
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
            history.append(content)
        }
    }

    func pasteToClipboard(content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
}
