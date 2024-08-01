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
        ScrollViewReader { scrollViewProxy in
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                List {
                    ForEach(clipboardManager.history, id: \.self) { item in
                        Text(item)
                            .id(item) // Ensure each item has a unique ID
                            .onTapGesture {
                                clipboardManager.pasteToClipboard(content: item)
                            }
                    }
                }
                .frame(minWidth: 300, minHeight: 400)
                .onChange(of: clipboardManager.history) { _ in
                    // Scroll to the top when history changes
                    if let firstItem = clipboardManager.history.first {
                        withAnimation {
                            scrollViewProxy.scrollTo(firstItem, anchor: .top)
                        }
                    }
                }
            }
            .onAppear {
                clipboardManager.startMonitoring()
            }
        }
    }
}

#Preview {
    ContentView()
}

