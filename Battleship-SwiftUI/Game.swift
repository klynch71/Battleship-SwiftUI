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
    let numCols: Int
    let numRows: Int
    var myOcean: Ocean
    var enemyOcean: Ocean
    var myFleet: Fleet
    var enemyFleet: Fleet
    @Published var myZoneStates = [[OceanZoneState]]()
    @Published var enemyZoneStates = [[OceanZoneState]]()
    @Published var message = ""
    var over: Bool {
        return myFleet.isDestroyed() || enemyFleet.isDestroyed()
    }
    
    init(numCols: Int, numRows: Int) {
        self.numRows = numRows
        self.numCols = numCols
        self.myOcean = Ocean(numCols: numCols, numRows: numRows)
        self.myFleet = Fleet()
        self.enemyOcean = Ocean(numCols: numCols, numRows: numRows)
        self.enemyFleet = Fleet()
        reset()
    }
    
    /*
     start a new game
     */
    func reset() {
        self.myZoneStates = defaultZoneStates()
        self.enemyZoneStates = defaultZoneStates()
        self.myFleet.deploy(on: self.myOcean)
        self.enemyFleet.deploy(on: self.enemyOcean)
        self.message = ""
    }
    
    /*
     handle when an OceanZoneView is tapped
     */
    func enemyZoneTapped(_ location: Coordinate) {
        
        //if we already tapped this location or the game is over, just ignore it
        if ((enemyZoneStates[location.x][location.y] != .clear) || over) {
            return
        }
        
        //see if we hit a ship
        if let hitShip = enemyFleet.ship(at: location) {
            hitShip.hit(at: location)
            enemyZoneStates[location.x][location.y] = .hit
            message = hitShip.isSunk() ? "You sunk enemy \(hitShip.name)!" : "Hit"
        } else {
            enemyZoneStates[location.x][location.y] = .miss
            message = "Miss"
        }
        
        //are we done?
        if (over) {
            message += " YOU WON!"
        }
    }

    func myZoneTapped(_ location: Coordinate) {
        //computer tapped my oceen location
        if ((myZoneStates[location.x][location.y] != .clear) || over) {
            return
        }

        //see if we hit a ship
        if let hitShip = myFleet.ship(at: location) {
            hitShip.hit(at: location)
            myZoneStates[location.x][location.y] = .hit
            message = hitShip.isSunk() ? "Enemy did sunk your \(hitShip.name)!" : "Hited"
        } else {
            myZoneStates[location.x][location.y] = .miss
            message = "Missed"
        }

        //are we done?
        if (over) {
            message += " YOU LOOSE!"
        }
    }
    
    /*
     create a two dimensional array of OceanZoneStates all set to .clear
     */
    private func defaultZoneStates() -> [[OceanZoneState]] {
        var states = [[OceanZoneState]]()
        for x in 0..<self.numCols {
            states.append([])
            for _ in 0..<self.numRows {
                states[x].append(.clear)
            }
        }
        return states
    }

}

