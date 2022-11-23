//
//  OceanZoneView.swift
//  Battleship-SwiftUI
//
//  Created by Kevin Lynch on 7/25/22.
//

import SwiftUI

/*
 represents a zone in an ocean
 A circle will be drawn if the state is not .clear
 */
struct OceanZoneView: View {
    @Binding var state: OceanZoneState
    var forceVisibility: Bool
    private let circleScale = CGSize(width: 0.5, height: 0.5)
    
    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(.black, lineWidth: 2)
                .background(.blue)

            switch state {
            case .clear(let isShip):
                if forceVisibility && isShip {
                    ScaledShape(shape: Rectangle(), scale: circleScale)
                        .fill(.white)
                        .opacity(0.8)
                } else {
                    EmptyView()
                }
            case .miss:
                ScaledShape(shape: Rectangle(), scale: circleScale)
                    .fill(.green)
                    .opacity(0.8)
            case .hit:
                ScaledShape(shape: Rectangle(), scale: circleScale)
                    .fill(.red)
                    .opacity(0.8)
            }
        }
    }
}

struct OceanZoneView_Previews: PreviewProvider {
    static var previews: some View {
        OceanZoneView(state: .constant(.miss), forceVisibility: true)
    }
}


