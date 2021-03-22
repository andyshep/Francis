//
//  ServiceTypesListView.swift
//  Shared
//
//  Created by Andrew Shepard on 8/2/20.
//

import SwiftUI

struct ServiceTypesListView: View {
    @EnvironmentObject var store: AppStore
    @State private var selection: NetService?
    
    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                Section(header: Text("_services._dns-sd._udp")) {
                    ForEach(store.state.servicesTypes) { serviceType in
                        #if os(iOS)
                        let destination = ServicesListView(
                            serviceType: serviceType
                        )
                        .environmentObject(store)
                        .navigationTitle(serviceType.name)
                        #elseif os(macOS)
                        let destination = ServicesListView(
                            serviceType: serviceType
                        )
                        #endif
                        NavigationLink(destination: destination) {
                            ServiceNameView(service: serviceType)
                        }
                    }
                }
            }
            Divider()
            StatusBar(
                label: "\(store.state.servicesTypes.count) services"
            )
        }
        .onAppear {
            store.send(.loadServiceTypes)
        }
    }
}

private struct StatusBar: View {
    var label: String
    
    var body: some View {
        Text(label)
            .font(.subheadline)
            .frame(height: 26)
    }
}
