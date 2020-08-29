//
//  ServiceView.swift
//  Francis
//
//  Created by Andrew Shepard on 8/28/20.
//

import SwiftUI

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

struct CustomAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        return context[.leading]
    }
}

extension HorizontalAlignment {
    static let custom: HorizontalAlignment = HorizontalAlignment(CustomAlignment.self)
}


//struct ServiceView_Previews: PreviewProvider {
//    static var previews: some View {
//        ServiceView()
//    }
//}
