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
    enum Ownership {
        case my
        case enemy
    }
    let ownership: Ownership
    var body: some View {
        let range = (0..<(game.numCols * game.numRows))
        let columns = [GridItem](repeating: GridItem(.flexible(), spacing: 0), count: game.numCols)
        GeometryReader {geo in
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(range, id: \.self) {index in
                    let y = index / game.numRows
                    let x = index - (y * game.numCols)
                    let location = Coordinate(x: x, y: y)
                    switch self.ownership {
                    case .my:
                        OceanZoneView(state: $game.myZoneStates[x][y])
                            .frame(height: geo.size.height/CGFloat(game.numRows))
                            .onTapGesture {
                                //game.myZoneTapped(location)
                            }
                    case .enemy:
                        OceanZoneView(state: $game.enemyZoneStates[x][y])
                            .frame(height: geo.size.height/CGFloat(game.numRows))
                            .onTapGesture {
                                game.enemyZoneTapped(location)
                            }
                    }
                }
            }
        }
    }
}

struct OceanView_Previews: PreviewProvider {
    static var previews: some View {
        OceanView(ownership: .my)
            .environmentObject(Game(numCols: 8, numRows: 8))
    }
}

