//
//  Game.swift
//  Battleship-SwiftUI
//
//  Created by Sebastian Kucera on 11/20/22.
//


import Foundation

/*
 represents a compartment within a ship which has a location and can also be flooded
 */
class ShipCompartment {
    var location: Coordinate = .zero
    var flooded: Bool = false
    
    init(location: Coordinate, flooded:Bool = false) {
        self.location = location
        self.flooded = flooded
    }
}

extension ShipCompartment: CustomStringConvertible {
    var description: String {
        return location.description
        }
}
