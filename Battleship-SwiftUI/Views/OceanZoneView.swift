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
    var color: Color {
        switch state {
        case .clear(let ship):
            if let ship = ship {
                switch ship.length {
                case 5:
                    return .gray
                case 4:
                    return .purple
                case 3:
                    return .orange
                case 2:
                    return .yellow
                default:
                    return .white
                }
            } else {
                return .clear
            }
        case .hit:
            return .red
        case .miss:
            return .green
        }
    }
    var forceVisibility: Bool
    private let circleScale = CGSize(width: 0.5, height: 0.5)
    
    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(.black, lineWidth: 2)
                .background(.white)

            switch state {
            case .clear(let ship):
                if forceVisibility, ship != nil {
                    ScaledShape(shape: Rectangle(), scale: circleScale)
                        .fill(self.color)
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


