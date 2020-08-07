//
//  ServiceViewModels.swift
//  Francis-SwiftUI
//
//  Created by Andrew Shepard on 8/28/19.
//  Copyright © 2019 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

class ServiceTypesViewModel: ObservableObject {
    @Published var serviceTypes: [NetService] = []
    
    private let serviceTypesProvider: ServiceTypesProvider
    private var cancellables: [AnyCancellable] = []
    
    init(serviceTypesProvider: ServiceTypesProvider) {
        self.serviceTypesProvider = serviceTypesProvider
        
        serviceTypesProvider.serviceTypes
//            .print()
            .assign(to: \.serviceTypes, on: self)
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

class ServicesViewModel: ObservableObject {
    @Published var services: [NetService] = []
    
    let servicesProvider: ServicesProvider
    private var cancellables: [AnyCancellable] = []
    
    init(servicesProvider: ServicesProvider) {
        self.servicesProvider = servicesProvider
     
        servicesProvider.services
            .assign(to: \.services, on: self)
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

class ServiceViewModel: ObservableObject {
    @Published var entries: [Entry] = []
    
    private let service: NetService
    private(set) lazy var serviceProvider = ServiceProvider(service: self.service)
    private var cancellables: [AnyCancellable] = []
    
    init(service: NetService) {
        self.service = service
        
        serviceProvider.entries
            .map { (dictionary) -> [Entry] in
                dictionary.reduce(into: [Entry]()) { (accumlator, input) in
                    let (key, value) = input
                    let entry = Entry(title: key, subtitle: value)
                    accumlator.append(entry)
                }
            }
            .assign(to: \.entries, on: self)
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

struct Entry: Identifiable {
    var id: UUID = UUID()
    
    let title: String
    let subtitle: String
}
