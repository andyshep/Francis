//
//  ColumnAppScene.swift
//  Francis (macOS)
//
//  Created by Andrew Shepard on 8/28/20.
//

import SwiftUI

struct ColumnAppScene: Scene {
    @ObservedObject var store: AppStore
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ServiceTypesListView()
                    .frame(
                        minWidth: 100,
                        idealWidth: 150,
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .environmentObject(store)

                Text("Select Service Type")
                Text("Select Service")
            }
            .toolbar {
                Button(action: refresh) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                Button(action: share) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
             }
        }
        .windowStyle(TitleBarWindowStyle())
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
    }
}

private extension ColumnAppScene {
    func refresh() {
        store.send(.refresh)
    }
    
    func share() {
        store.send(.share)
    }
}
