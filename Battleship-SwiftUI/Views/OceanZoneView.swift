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
    private let circleScale = CGSize(width: 0.5, height: 0.5)
    
    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(.black, lineWidth: 2)
                .background(.blue)
            
            if (state != .clear) {
                ScaledShape(shape: Rectangle(), scale: circleScale)
                    .fill(circleColor())
                    .opacity(0.8)
                
            }
        }
    }
    
    func circleColor() -> Color {
        return (state == .hit) ? .red : .green
    }
}

struct OceanZoneView_Previews: PreviewProvider {
    static var previews: some View {
        OceanZoneView(state: .constant(.miss))
    }
}


