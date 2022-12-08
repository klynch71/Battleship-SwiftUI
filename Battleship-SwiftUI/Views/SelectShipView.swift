//
//  SelectShipView.swift
//  Battleship-SwiftUI
//
//  Created by Sebastián Kučera on 22.11.2022.
//

import SwiftUI

struct SelectShipView: View {
    var body: some View {
        OceanView(ownership: .my)
        NavigationView {
                  VStack {
                      Text("Hello World")
                      NavigationLink(destination: ContentView()) {
                          Text("Do Something")
                      }
                  }
              }
    }
}

struct SelectShipView_Previews: PreviewProvider {
    static var previews: some View {
        SelectShipView()
    }
}
