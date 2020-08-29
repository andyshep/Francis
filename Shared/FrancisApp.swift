//
//  FrancisApp.swift
//  Francis (iOS)
//
//  Created by Andrew Shepard on 8/28/20.
//

import SwiftUI

typealias AppStore = Store<AppState, AppAction, AppEnvironment>

@main
struct FrancisApp: App {
    
    @StateObject private var store = AppStore(
        initial: .init(),
        reducer: appReducer,
        environment: AppEnvironment(
            serviceTypesProvider: ServiceTypesProvider()
        )
    )
    
    var body: some Scene {
        #if os(iOS)
        CompactAppScene(store: store)
        #else
        ColumnAppScene(store: store)
        #endif
    }
}
