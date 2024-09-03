//
//  ContentView.swift
//  Clipboard
//
//  Created by Luke Cai on 30/7/2024.
//

import SwiftUI


struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                List {
                    ForEach(clipboardManager.history.indices, id: \.self) { index in
                        let item = clipboardManager.history[index]
                        Text(item)
                            .id(index) // Use the index as a unique ID
                            .onTapGesture {
                                clipboardManager.pasteToClipboard(content: item)
                            }
                    }
                }
                .frame(minWidth: 300, minHeight: 400)
                .onChange(of: clipboardManager.history) { oldValue, newValue in
                    // Scroll to the top when history changes
                    if let firstItem = newValue.first, oldValue != newValue {
                        withAnimation {
                            scrollViewProxy.scrollTo(clipboardManager.history.firstIndex(of: firstItem), anchor: .top)
                        }
                    }
                }            }
            .onAppear {
                clipboardManager.startMonitoring()
            }
        }
    }
}

#Preview {
    ContentView(clipboardManager: ClipboardManager())
}
