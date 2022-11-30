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
    var suggestedLocation: Coordinate?
    var directionToLastHit: Coordinate.ComparsionVector?
    
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
        self.directionToLastHit = nil
        self.suggestedLocation = nil
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
                if hitShip.isSunk() {
                    message = "Enemy did sunk your \(hitShip.name)!"
                    self.lastHittedLocation = nil
                    self.directionToLastHit = nil
                } else {
                    message = "Hited at x:\(location.x), y:\(location.y)"
                }
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
        guard var location = clearLocations.randomElement() else { return }

        if let suggestedLocation = self.suggestedLocation {
            location = suggestedLocation
        } else if let lastHittedLocation = self.lastHittedLocation {
            // find from clearLocations nearest location to lastHittedLocation
            // temporary use random
            var nearestLocations = [Coordinate]() // array of possible nearest neighbougrs
            for clearLocation in clearLocations {
                let x = clearLocation.x
                let y = clearLocation.y
                
                if (lastHittedLocation.y == y + 1 && lastHittedLocation.x == x) // up
                    || (lastHittedLocation.y == y - 1 && lastHittedLocation.x == x) // down
                    || (lastHittedLocation.x == x - 1 && lastHittedLocation.y == y) // left
                    || (lastHittedLocation.x == x + 1 && lastHittedLocation.y == y) { // right
                    nearestLocations.append(clearLocation)
                }
            }
            if let directionToLastHit = self.directionToLastHit, let lastHittedLocation = self.lastHittedLocation  {
                // calculate location by direction
                var calculatedLocation = Coordinate( // copy the last hit
                    x: lastHittedLocation.x,
                    y: lastHittedLocation.y
                )
                switch directionToLastHit {
                case .top:
                    if calculatedLocation.y > 0 {
                        calculatedLocation.y -= 1
                        if clearLocations.contains(calculatedLocation) {
                            location = calculatedLocation
                        }
                    }
                case .bottom:
                    if calculatedLocation.y < self.numRows - 1 {
                        calculatedLocation.y += 1
                        if clearLocations.contains(calculatedLocation) {
                            location = calculatedLocation
                        }
                    }
                case .left:
                    if calculatedLocation.x > 0 {
                        calculatedLocation.x -= 1
                        if clearLocations.contains(calculatedLocation) {
                            location = calculatedLocation
                        }
                    }
                case .right:
                    if calculatedLocation.x < self.numCols - 1 {
                        calculatedLocation.x += 1
                        if clearLocations.contains(calculatedLocation) {
                            location = calculatedLocation
                        }
                    }
                default:
                    break
                }

            } else if let foundLocation = nearestLocations.randomElement() {
                location = foundLocation
            }
        }

        let hit = self.myZoneTapped(location)
        if hit {
            // was there last hitted location before?
            if let lastHittedLocation = self.lastHittedLocation {
                self.directionToLastHit = lastHittedLocation.compare(location)
            }
            self.lastHittedLocation = location
            self.suggestedLocation = nil
        } else {
            // handle last hist location and direction to last hit
            if let directionToLastHit = self.directionToLastHit, let lastHittedLocation = self.lastHittedLocation {
                let x = lastHittedLocation.x
                let y = lastHittedLocation.y

                switch directionToLastHit {
                case .top:
                    let locationsForTop = clearLocations.filter { location in
                        return location.x == x && location.y > y
                    }
                    if let nearestLocationForTop = locationsForTop.sorted(by: { location1, location2 in
                        return location1.y < location2.y
                    }).first {
                        self.suggestedLocation = nearestLocationForTop
                    }
                case .bottom:
                    let locationsForBottom = clearLocations.filter { location in
                        return location.x == x && location.y < y
                    }
                    if let nearestLocationForBottom = locationsForBottom.sorted(by: { location1, location2 in
                        return location1.y > location2.y
                    }).first {
                        self.suggestedLocation = nearestLocationForBottom
                    }
                case .left:
                    let locationsForLeft = clearLocations.filter { location in
                        return location.y == y && location.x < x
                    }
                    if let nearestLocationForLeft = locationsForLeft.sorted(by: { location1, location2 in
                        return location1.x > location2.x
                    }).first {
                        self.suggestedLocation = nearestLocationForLeft
                    }
                case .right:
                    let locationsForRight = clearLocations.filter { location in
                        return location.y == y && location.x > x
                    }
                    if let nearestLocationForRight = locationsForRight.sorted(by: { location1, location2 in
                        return location1.x < location2.x
                    }).first {
                        self.suggestedLocation = nearestLocationForRight
                    }
                default:
                    break
                }

            } else {
                self.directionToLastHit = nil
                self.lastHittedLocation = nil
                self.suggestedLocation = nil
                // go for random location
            }
        }
    }

    func findAllClearLocations() -> [Coordinate] {
        var locations = [Coordinate]()
        for (x, states) in self.myZoneStates.enumerated() {
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

