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

    enum ShipHitStatus {
        case miss
        case hit
        case sunk
        case over
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
    func enemyZoneTapped(_ location: Coordinate) -> ShipHitStatus {
        guard !over else {
            message = "YOU LOST !"
            return .over
        }

        var status: ShipHitStatus = .miss
        if case .clear = enemyZoneStates[location.x][location.y] {
            self.messageAmo += 1
            if let hitShip = enemyFleet.ship(at: location) {
                hitShip.hit(at: location)
                enemyZoneStates[location.x][location.y] = .hit
                if hitShip.isSunk() {
                    message = "You sunk enemy \(hitShip.name)!"
                    status = .sunk
                } else {
                    message = "Hit at x:\(location.x), y:\(location.y)"
                    status = .hit
                }
            } else {
                enemyZoneStates[location.x][location.y] = .miss
                message = "Miss"
            }

            Task {
                let duration = UInt64(0.5 * 1_000_000_000) // nanoseconds
                await self.delayedAction(for: duration)
            }
        }
        return status
    }

    func myZoneTapped(_ location: Coordinate) -> ShipHitStatus {
        guard !over else {
            message = "YOU WON !"
            return .over
        }

        var status: ShipHitStatus = .miss
        if case .clear = myZoneStates[location.x][location.y] {
            //see if we hit a ship
            if let hitShip = myFleet.ship(at: location) {
                hitShip.hit(at: location)
                myZoneStates[location.x][location.y] = .hit
                if hitShip.isSunk() {
                    message = "Enemy did sunk your \(hitShip.name)!"
                    status = .sunk

                    self.lastHittedLocation = nil
                    self.directionToLastHit = nil
                    self.suggestedLocation = nil
                } else {
                    message = "Hited at x:\(location.x), y:\(location.y)"
                    status = .hit
                }
            } else {
                myZoneStates[location.x][location.y] = .miss
                message = "Missed at x:\(location.x), y:\(location.y)"
            }
        }
        return status
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
                let ship = fleet.ship(at: location)
                states[x].append(.clear(ship))
            }
        }
        return states
    }

    func delayedAction(for nanoseconds: UInt64) async {
        try? await Task.sleep(nanoseconds: nanoseconds)
        await MainActor.run {
            self.performEnemyRandomFire()
        }
    }

    func performEnemyRandomFire() {
        let clearLocations = findAllClearLocations()
        guard var location = clearLocations.randomElement() else { return }

        if let suggestedLocation = self.suggestedLocation {
            location = suggestedLocation
            self.suggestedLocation = nil
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
            if let directionToLastHit = self.directionToLastHit  {
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
                        } else {
                            if let suggestedLocation = self.suggestLocation(available: clearLocations) {
                                location = suggestedLocation
                            }
                        }
                    } else {
                        if let suggestedLocation = self.suggestLocation(available: clearLocations) {
                            location = suggestedLocation
                        }
                    }
                case .bottom:
                    if calculatedLocation.y < self.numRows - 1 {
                        calculatedLocation.y += 1
                        if clearLocations.contains(calculatedLocation) {
                            location = calculatedLocation
                        } else {
                            if let suggestedLocation = self.suggestLocation(available: clearLocations) {
                                location = suggestedLocation
                            }
                        }
                    } else {
                        if let suggestedLocation = self.suggestLocation(available: clearLocations) {
                            location = suggestedLocation
                        }
                    }
                case .left:
                    if calculatedLocation.x > 0 {
                        calculatedLocation.x -= 1
                        if clearLocations.contains(calculatedLocation) {
                            location = calculatedLocation
                        } else {
                            if let suggestedLocation = self.suggestLocation(available: clearLocations) {
                                location = suggestedLocation
                            }
                        }
                    } else {
                        if let suggestedLocation = self.suggestLocation(available: clearLocations) {
                            location = suggestedLocation
                        }
                    }
                case .right:
                    if calculatedLocation.x < self.numCols - 1 {
                        calculatedLocation.x += 1
                        if clearLocations.contains(calculatedLocation) {
                            location = calculatedLocation
                        } else {
                            if let suggestedLocation = self.suggestLocation(available: clearLocations) {
                                location = suggestedLocation
                            }
                        }
                    } else {
                        if let suggestedLocation = self.suggestLocation(available: clearLocations) {
                            location = suggestedLocation
                        }
                    }
                default:
                    break
                }

            } else if let foundLocation = nearestLocations.randomElement() {
                location = foundLocation
            }
        }

        let hitStatus = self.myZoneTapped(location)

        // filter last location
        let stillAvailableClearLocations = clearLocations.filter { tempLocation in
            return tempLocation != location
        }

        if hitStatus == .miss {
            self.suggestedLocation = suggestLocation(available: stillAvailableClearLocations)
        } else if hitStatus == .hit {
            if let lastHittedLocation = self.lastHittedLocation {
                self.directionToLastHit = lastHittedLocation.compare(location)
            }
             
            self.lastHittedLocation = location
            self.suggestedLocation = nil
        } else if hitStatus == .sunk {
            self.lastHittedLocation = nil
            self.directionToLastHit = nil
            self.suggestedLocation = nil
        }
    }

    func suggestLocation(available stillAvailableClearLocations: [Coordinate]) -> Coordinate? {
        if let lastHittedLocation = self.lastHittedLocation {
            let x = lastHittedLocation.x
            let y = lastHittedLocation.y

            if let directionToLastHit = self.directionToLastHit {
                switch directionToLastHit {
                case .top:
                    let locationsForTop = stillAvailableClearLocations.filter { location in
                        return location.x == x && location.y > y
                    }
                    if let nearestLocationForTop = locationsForTop.sorted(by: { location1, location2 in
                        return location1.y < location2.y
                    }).first {
                        return nearestLocationForTop
                    }
                case .bottom:
                    let locationsForBottom = stillAvailableClearLocations.filter { location in
                        return location.x == x && location.y < y
                    }
                    if let nearestLocationForBottom = locationsForBottom.sorted(by: { location1, location2 in
                        return location1.y > location2.y
                    }).first {
                        return nearestLocationForBottom
                    }
                case .right:
                    let locationsForLeft = stillAvailableClearLocations.filter { location in
                        return location.y == y && location.x < x
                    }
                    if let nearestLocationForLeft = locationsForLeft.sorted(by: { location1 , location2 in
                        return location1.x > location2.x
                    }).first {
                        return nearestLocationForLeft

                    }
                case .left:
                    let locationsForRight = stillAvailableClearLocations.filter { location in
                        return location.y == y && location.x < x
                    }
                    if let nearestLocationForRight = locationsForRight.sorted(by: { location1, location2 in
                        return location1.x < location2.x
                    }).first {
                        return nearestLocationForRight
                    }
                default:
                    break
                }
            }
        }
        return nil
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

