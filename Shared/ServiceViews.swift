//
//  ServiceViews.swift
//  Shared
//
//  Created by Andrew Shepard on 8/2/20.
//

import SwiftUI

struct ServiceTypesListView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        VStack(spacing: 0) {
            List {
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
            StatusBarView(
                label: "\(store.state.servicesTypes.count) services"
            )
        }
        .onAppear {
            store.send(.loadServiceTypes)
        }
    }
}

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

struct ServiceView: View {
    @EnvironmentObject var store: AppStore
    
    private let service: NetService
    
    init(service: NetService) {
        self.service = service
    }
    
    var body: some View {
        List {
            VStack(alignment: .custom) {
                HeaderView(title1: "Key", title2: "Value")
                    .padding(.top, 5)
                ForEach(store.state.records, id: \.self) { entry in
                    EntryView(title: entry.title, subtitle: entry.subtitle)
                        .padding(2)
//                        .background((self.selectedValue == entry) ? Color.red : Color.clear)
//                        .onTapGesture {
//                            self.selectedValue = entry
//                        }
                }
            }
        }
        .listStyle(PlainListStyle())
        .padding(0)
        .onAppear {
            store.send(.loadServiceRecord(service: service))
        }
    }
}

struct ServiceNameView: View {
    var service: NetService
    
    var body: some View {
        Text(service.name)
            .padding(3)
    }
}

struct EntryView: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Color.secondary)
            Text(subtitle)
                .font(.system(.body, design: .monospaced))
                .alignmentGuide(.custom) { $0[.leading] + 8 }
        }
    }
}

struct HeaderView: View {
    var title1: String
    var title2: String
    
    var body: some View {
        HStack {
            Text(title1)
                .font(Font.subheadline.bold().smallCaps())
            Text(title2)
                .font(Font.subheadline.bold().smallCaps())
                .alignmentGuide(.custom) { $0[.leading] + 8 }
        }
    }
}

struct StatusBarView: View {
    var label: String
    
    var body: some View {
        Text(label)
            .font(.subheadline)
            .frame(height: 26)
    }
}

struct CustomAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        return context[.leading]
    }
}

extension HorizontalAlignment {
    static let custom: HorizontalAlignment = HorizontalAlignment(CustomAlignment.self)
}
