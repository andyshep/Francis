//
//  ServiceViews.swift
//  Shared
//
//  Created by Andrew Shepard on 8/2/20.
//

import SwiftUI

struct ServiceTypesListView: View {
    @ObservedObject var viewModel: ServiceTypesViewModel
    
    @Binding var selectedServiceType: NetService?
    @Binding var selectedService: NetService?
    
    var body: some View {
        List(selection: $selectedServiceType) {
            ForEach(viewModel.serviceTypes) { serviceType in
                let destination = ServicesListView(
                    serviceType: serviceType,
                    selectedService: $selectedService
                )
                NavigationLink(destination: destination) {
                    ServiceNameView(service: serviceType)
                }
            }
        }
    }
}

struct ServicesListView: View {
    @ObservedObject var viewModel: ServicesViewModel
    @Binding var selectedService: NetService?
    
    init(serviceType: NetService, selectedService: Binding<NetService?>) {
        let provider = ServicesProvider(service: serviceType)
        self.viewModel = ServicesViewModel(servicesProvider: provider)
        self._selectedService = selectedService
    }
    
    var body: some View {
        List(selection: $selectedService) {
            ForEach(viewModel.services) { service in
                NavigationLink(destination: ServiceView(service: service)) {
                    ServiceNameView(service: service)
                }
            }
        }
//        #if os(iOS)
//        .navigationTitle("Services")
////        #endif
        .onAppear {
            self.viewModel.servicesProvider.refreshEvent.send(())
        }
    }
}

struct ServiceView: View {
    @ObservedObject var viewModel: ServiceViewModel
    
    private let service: NetService
    
    init(service: NetService) {
        self.service = service
        self.viewModel = ServiceViewModel(service: service)
    }
    
    var body: some View {
        List(viewModel.entries) { entry in
            EntryView(entry: entry)
        }
        .onAppear {
            self.viewModel.serviceProvider.refreshEvent.send(())
        }
        .navigationTitle(self.service.name)
    }
}

struct ServiceNameView: View {
    var service: NetService
    
    var body: some View {
        Text(service.name)
    }
}

struct EntryView: View {
    var entry: Entry
    
    var body: some View {
        VStack {
            Text(entry.title)
            Text(entry.subtitle)
        }
    }
}
