//
//  Game.swift
//  Battleship-SwiftUI
//
//  Created by Sebastian Kucera on 11/20/22.
//

import Foundation
import Combine


/*
 The classic Battleship game
 */
final class Game: ObservableObject {
    
    var amonution: Int = 20
    let numCols: Int
    let numRows: Int
    var myOcean: Ocean
    var enemyOcean: Ocean
    var myFleet: Fleet
    var enemyFleet: Fleet
    @Published var myZoneStates = [[OceanZoneState]]()
    @Published var enemyZoneStates = [[OceanZoneState]]()
    @Published var message = ""
    @Published var messageAmo: Int = 0
    var over: Bool {
        return myFleet.isDestroyed() || enemyFleet.isDestroyed()
    }
    var lastHittedLocation: Coordinate?
    
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
        self.myFleet.deploy(on: self.myOcean)
        self.enemyFleet.deploy(on: self.enemyOcean)
        self.myZoneStates = defaultZoneStates(for: self.myFleet)
        self.enemyZoneStates = defaultZoneStates(for: self.enemyFleet)
        self.message = ""
        self.messageAmo = 0
        self.lastHittedLocation = nil
    }
    
    /*
     handle when an OceanZoneView is tapped
     */
    func enemyZoneTapped(_ location: Coordinate) -> Bool {
        guard !over else {
            message = "YOU WON!"
            return false
        }

        var hit = false
        if case .clear = enemyZoneStates[location.x][location.y] {
            self.messageAmo += 1
            if let hitShip = enemyFleet.ship(at: location) {
                hitShip.hit(at: location)
                enemyZoneStates[location.x][location.y] = .hit
                message = hitShip.isSunk() ? "You sunk enemy \(hitShip.name)!" : "Hit"
                hit = true
            } else {
                enemyZoneStates[location.x][location.y] = .miss
                message = "Miss"
            }

            Task {
                let duration: Duration = .seconds(1)
                await self.delayedAction(for: duration)
            }
        }
        return hit
    }

    func myZoneTapped(_ location: Coordinate) -> Bool {
        guard !over else {
            message = "YOU LOST!"
            return false
        }

        var hit = false
        if case .clear = myZoneStates[location.x][location.y] {
            self.messageAmo += 1
            //see if we hit a ship
            if let hitShip = myFleet.ship(at: location) {
                hitShip.hit(at: location)
                myZoneStates[location.x][location.y] = .hit
                message = hitShip.isSunk() ? "Enemy did sunk your \(hitShip.name)!" : "Hited at x:\(location.x), y:\(location.y)"
                hit = true
            } else {
                myZoneStates[location.x][location.y] = .miss
                message = "Missed at x:\(location.x), y:\(location.y)"
            }
        }
        return hit
    }
    
    /*
     create a two dimensional array of OceanZoneStates all set to .clear
     */
    private func defaultZoneStates(for fleet: Fleet) -> [[OceanZoneState]] {
        var states = [[OceanZoneState]]()
        for x in 0..<self.numCols {
            states.append([])
            for y in 0..<self.numRows {
                let location = Coordinate(x: x, y: y)
                if fleet.ship(at: location) != nil {
                    states[x].append(.clear(true))
                } else {
                    states[x].append(.clear(false))
                }
            }
        }
        return states
    }

    func delayedAction(for duration: Duration) async {
        try? await Task.sleep(for: duration)
        await MainActor.run {
            self.performEnemyRandomFire()
        }
    }

    func performEnemyRandomFire() {
        let clearLocations = findAllClearLocations()
        let randomIndex = Int.random(in: 0..<clearLocations.count)
        var location: Coordinate
        if let lastHittedLocation = self.lastHittedLocation {
            // find from clearLocations nearest location to lastHittedLocation
            // temporary use random
            var nearestLocations = [Coordinate]()
            for clearLocation in clearLocations {
                let x = clearLocation.x
                let y = clearLocation.y

                if (lastHittedLocation.x == x - 1 || lastHittedLocation.x == x + 1 || lastHittedLocation.x == x)
                    && (lastHittedLocation.y == y - 1 || lastHittedLocation.y == y + 1 || lastHittedLocation.y == y)
                    && !(lastHittedLocation.x == x && lastHittedLocation.y == y)
                {
                    nearestLocations.append(clearLocation)
                }
            }
            if let foundLocation = nearestLocations.randomElement() {
                location = foundLocation
            } else {
                location = clearLocations[randomIndex]
            }

        } else {
            location = clearLocations[randomIndex]
        }

        let hit = self.myZoneTapped(location)
        if hit {
            self.lastHittedLocation = location
        }
    }

    func findAllClearLocations() -> [Coordinate] {
        var locations = [Coordinate]()
        for (x, states) in self.enemyZoneStates.enumerated() {
            for (y, state) in states.enumerated() {
                if case .clear = state {
                    let location = Coordinate(x: x, y: y)
                    locations.append(location)
                }
            }
        }
        return locations
    }
}

