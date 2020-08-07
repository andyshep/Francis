//
//  FrancisApp.swift
//  Francis (iOS)
//
//  Created by Andrew Shepard on 8/6/20.
//

import SwiftUI

@main
struct FrancisApp: App {
    
    @StateObject private var provider = ServiceTypesProvider()
    
    @State private var selectedServiceType: NetService?
    @State private var selectedService: NetService?
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ServiceTypesListView(
                    viewModel: ServiceTypesViewModel(serviceTypesProvider: provider),
                    selectedServiceType: $selectedServiceType,
                    selectedService: $selectedService
                )
                .navigationTitle("Service Types")
                .toolbar {
                     Button(action: refresh) {
                         Label("Refresh", systemImage: "arrow.clockwise")
                     }
                }
            }
        }
    }
    
    private func refresh() {
        
    }
}
