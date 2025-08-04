//
//  ContentView.swift
//  SnapshotHelperApp
//
//  Created by Michael Danylchuk on 8/3/25.
//

import SwiftUI

struct ContentView: View {
    var onShowTimeline: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Show Timeline") {
                onShowTimeline()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView(onShowTimeline: {})
}
