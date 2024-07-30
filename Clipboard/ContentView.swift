//
//  ContentView.swift
//  Clipboard
//
//  Created by Luke Cai on 30/7/2024.
//

import SwiftUI


struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            List(clipboardManager.history, id: \.self) { item in
                Text(item)
                    .onTapGesture {
                        clipboardManager.pasteToClipboard(content: item)
                    }
            }
            .frame(minWidth: 300, minHeight: 400)
        }
        .padding()
        .onAppear {
            clipboardManager.startMonitoring()
        }
    }
}

#Preview {
    ContentView()
}

