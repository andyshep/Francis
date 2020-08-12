//
//  AppState.swift
//  Francis
//
//  Created by Andrew Shepard on 8/9/20.
//

import SwiftUI
import Combine

struct AppState {
    var servicesTypes: [NetService] = []
    var services: [NetService] = []
    var records: [Entry] = []
}

enum AppAction {
    case loadServiceTypes
    case setServiceTypes(servicesTypes: [NetService])
    
    case loadServices(serviceType: NetService)
    case setServices(services: [NetService])
    
    case loadServiceRecord(service: NetService)
    case setServiceRecord(record: [Entry])
    
    case refresh
    case share
}

typealias Reducer<State, Action, Environment> =
    (inout State, Action, Environment) -> AnyPublisher<Action, Never>?

final class Store<State, Action, Environment>: ObservableObject {
    @Published private(set) var state: State
    
    private let reducer: Reducer<State, Action, Environment>
    private let environment: Environment
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(initial state: State,
         reducer: @escaping Reducer<State, Action, Environment>,
         environment: Environment) {
        self.state = state
        self.reducer = reducer
        self.environment = environment
    }

    func send(_ action: Action) {
        guard let effect = reducer(&state, action, environment) else {
            return
        }

        effect
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &cancellables)
    }
}

func appReducer(
    state: inout AppState,
    action: AppAction,
    environment: AppEnvironment
) -> AnyPublisher<AppAction, Never>? {
    switch action {
    case .setServiceTypes(let servicesTypes):
        state.servicesTypes = servicesTypes
        state.services = []
        state.records = []
    case .loadServiceTypes:
        return environment.serviceTypesProvider
            .publisherForServiceTypes()
            .replaceError(with: [])
            .map { AppAction.setServiceTypes(servicesTypes: $0) }
            .eraseToAnyPublisher()
        
    case .setServices(let services):
        state.services = services
        state.records = []
    case .loadServices(let serviceType):
        return environment.serviceTypesProvider
            .publisherForServices(for: serviceType)
            .replaceError(with: [])
            .map { AppAction.setServices(services: $0) }
            .eraseToAnyPublisher()
        
    case .setServiceRecord(let record):
        state.records = record
    case .loadServiceRecord(let service):
        return environment.serviceTypesProvider
            .publisherForServiceRecord(for: service)
            .replaceError(with: [])
            .map { AppAction.setServiceRecord(record: $0) }
            .eraseToAnyPublisher()
    
    case .refresh:
        state.servicesTypes = []
        state.services = []
        state.records = []
        return Just(())
            .map { AppAction.loadServiceTypes }
            .eraseToAnyPublisher()
        
    case .share:
        print("\(#function) handle action")
    }
    return nil
}
