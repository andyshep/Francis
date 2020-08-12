//
//  FrancisApp.swift
//  Francis (macOS)
//
//  Created by Andrew Shepard on 8/6/20.
//

import SwiftUI

typealias AppStore = Store<AppState, AppAction, AppEnvironment>

@main
struct FrancisApp: App {
    
    private let store = AppStore(
        initial: .init(),
        reducer: appReducer,
        environment: AppEnvironment()
    )
    
    @ViewBuilder
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
    
    private func refresh() {
        store.send(.refresh)
    }
    
    private func share() {
        store.send(.share)
    }
}

