//
//  FrancisApp.swift
//  Francis (macOS)
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

                if let serviceType = selectedServiceType {
                    ServicesListView(serviceType: serviceType, selectedService: $selectedService)
                } else {
                    Text("Select Service Type")
                }
                
                if let service = selectedService {
                    ServiceView(service: service)
                } else {
                    Text("Select Service")
                }
            }
//            .navigationTitle("")
            .toolbar {
                 Button(action: refresh) {
                     Label("Refresh", systemImage: "arrow.clockwise")
                 }
             }
        }
        .windowStyle(TitleBarWindowStyle())
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
    }
    
    private func refresh() {
        
    }
}
