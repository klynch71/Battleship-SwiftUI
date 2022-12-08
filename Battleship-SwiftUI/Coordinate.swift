//
//  Game.swift
//  Battleship-SwiftUI
//
//  Created by Sebastian Kucera on 11/20/22.
//


import Foundation

/*
 a simple x,y coordinate
 */
struct Coordinate: Hashable {
    var x: Int = 0
    var y: Int = 0
    static var zero = Coordinate(x: 0, y: 0)
    
    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    enum ComparsionVector {
        case equal
        case top
        case right
        case bottom
        case left
        case invalid
    }

    func compare(_ other: Coordinate) -> ComparsionVector {
        switch (self.x - other.x, self.y - other.y) {
        case (0, 0):
            return .equal

        case (let deltaX, 0):
            if deltaX >= 0 {
                return .left
            } else {
                return .right
            }

        case (0, let deltaY):
            if deltaY >= 0 {
                return .top
            } else {
                return .bottom
            }
        default:
            return .invalid
        }
    }
}

extension Coordinate: CustomStringConvertible {
    var description: String {
            return "(\(x), \(y))"
        }
}
