//
//  Game.swift
//  Battleship-SwiftUI
//
//  Created by Kevin Lynch on 7/25/22.
//

import Foundation
import Combine

/*
 The classic Battleship game
 */
final class Game: ObservableObject {
    static let numCols = 10
    static let numRows = 10
    var ocean: Ocean
    var fleet: Fleet
    @Published var zoneStates = [[OceanZoneState]]()
    @Published var message = ""
    
    init() {
        self.ocean = Ocean(numCols: Game.numCols, numRows: Game.numRows)
        self.fleet = Fleet()
        reset()
    }
    
    /*
     start a new game
     */
    func reset() {
        self.zoneStates = defaultZoneStates()
        self.fleet.deploy(on: self.ocean)
        self.message = ""
    }
    
    /*
     handle when an OceanZoneView is tapped
     */
    func zoneTapped(_ location: Coordinate) {
        //if we already tapped this location, just ignore it
        if (zoneStates[location.x][location.y] != .clear) {
            message = ""
            return
        }
        
        //see if we hit a ship
        if let hitShip = fleet.ship(at: location) {
            hitShip.hit(at: location)
            zoneStates[location.x][location.y] = .hit
            message = hitShip.isSunk() ? "You sunk my \(hitShip.name)!" : "Hit"
        } else {
            zoneStates[location.x][location.y] = .miss
            message = "Miss"
        }
        
        //are we done?
        if (fleet.isDestroyed()) {
            message += " YOU WIN!"
        }
    }
    
    /*
     create a two dimensional array of OceanZoneStates all set to .clear
     */
    private func defaultZoneStates() -> [[OceanZoneState]] {
        var states = [[OceanZoneState]]()
        for x in 0..<Game.numCols {
            states.append([])
            for _ in 0..<Game.numRows {
                states[x].append(.clear)
            }
        }
        return states
    }

}

