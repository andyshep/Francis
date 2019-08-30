//
//  ContentView.swift
//  Francis-SwiftUI
//
//  Created by Andrew Shepard on 8/28/19.
//  Copyright © 2019 Andrew Shepard. All rights reserved.
//

import SwiftUI

struct ServiceTypesListView: View {
    @ObservedObject var viewModel: ServiceTypesViewModel
    
    var body: some View {
        NavigationView {
            List(viewModel.serviceTypes) { service in
                NavigationLink(destination: ServicesListView(service: service)) {
                    ServiceNameView(service: service)
                }
            }
            .navigationBarTitle(Text("Services Types"))
        }
    }
}

struct ServicesListView: View {
    @ObservedObject var viewModel: ServicesViewModel
    
    init(service: NetService) {
        let provider = ServicesProvider(service: service)
        self.viewModel = ServicesViewModel(servicesProvider: provider)
    }
    
    var body: some View {
        List(viewModel.services) { service in
            NavigationLink(destination: ServiceView(service: service)) {
                ServiceNameView(service: service)
            }
        }
        .onAppear {
            self.viewModel.servicesProvider.refreshEvent.send(())
        }
        .navigationBarTitle(Text("Services"))
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
        .navigationBarTitle(self.service.name)
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
