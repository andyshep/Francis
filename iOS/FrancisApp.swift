//
//  FrancisApp.swift
//  Francis (iOS)
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
    
    @State private var selectedService: NetService?
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ServiceTypesListView()
                    .listStyle(PlainListStyle())
                    .navigationTitle("Service Types")
                    .environmentObject(store)
//                .toolbar {
//                     Button(action: refresh) {
//                         Label("Refresh", systemImage: "arrow.clockwise")
//                     }
//                }
            }
        }
    }
    
    private func refresh() {
        
    }
}
