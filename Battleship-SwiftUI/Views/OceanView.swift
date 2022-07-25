//
//  OceanView.swift
//  Battleship-SwiftUI
//
//  Created by Kevin Lynch on 7/25/22.
//

import SwiftUI

/*
 An OceanView consists of a grid of OceanZoneViews
 */
struct OceanView: View {
    @EnvironmentObject var game: Game
    let range = (0..<(Game.width * Game.height))
    let columns = [GridItem](repeating: GridItem(.flexible(), spacing: 0), count: Game.width)
    
    var body: some View {
        GeometryReader {geo in
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(range, id: \.self) {index in
                    let y = index / Game.height
                    let x = index - (y * Game.width)
                    let location = Coordinate(x: x, y: y)
                    OceanZoneView(state: $game.zoneStates[x][y])
                        .frame(height: geo.size.height/CGFloat(Game.height))
                        .onTapGesture {
                            game.zoneTapped(location)
                        }
                    
                }
            }
        }
    }
}

struct OceanView_Previews: PreviewProvider {
    static var previews: some View {
        OceanView()
            .environmentObject(Game())
    }
}

