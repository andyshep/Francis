//
//  Sidebar.swift
//  Francis (macOS)
//
//  Created by Andrew Shepard on 8/4/20.
//

import SwiftUI

struct Sidebar<Selection: Hashable, Content: View>: View {
    @Binding private var selection: Selection?
    let content: Content
    
    init(selection: Binding<Selection?>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
    }
    
    var body: some View {
        List(selection: $selection) {
            content
        }
    }
}

//struct Sidebar_Previews: PreviewProvider {
//    static var previews: some View {
//        Sidebar<String>()
//    }
//}
