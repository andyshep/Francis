//
//  ServicesListView.swift
//  Francis
//
//  Created by Andrew Shepard on 8/28/20.
//

import SwiftUI

struct ServicesListView: View {
    @EnvironmentObject var store: AppStore
    
    let serviceType: NetService
    
    var body: some View {
        List(store.state.services) { service in
            let destination = ServiceView(service: service)
                .environmentObject(store)
            NavigationLink(destination: destination) {
                ServiceNameView(service: service)
            }
        }
        .listStyle(PlainListStyle())
        .onAppear {
            store.send(.loadServices(serviceType: serviceType))
        }
    }
}

//struct ServicesListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ServicesListView()
//    }
//}
