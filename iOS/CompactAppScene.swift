//
//  CompactAppScene.swift
//  Francis (iOS)
//
//  Created by Andrew Shepard on 8/28/20.
//

import SwiftUI

struct CompactAppScene: Scene {
    @ObservedObject var store: AppStore
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ServiceTypesListView()
                    .listStyle(PlainListStyle())
                    .navigationTitle("Service Types")
                    .environmentObject(store)
            }
        }
    }
}
