//
//  Ocean.swift
//  Battleship-SwiftUI
//
//  Created by Kevin Lynch on 7/25/22.
//

import Foundation

/*
 represents an Ocean of a certain size in Coordinate space with
 the origin always at (0, 0)
 */
struct Ocean {
    var width: Int
    var height: Int
    private var origin: Coordinate = .zero
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    /*
     return true if this ocean contains the coordinate point
     */
    func contains(_ point: Coordinate) ->Bool
    {
        return (point.x >= origin.x && point.y >= origin.y && point.x < width && point.y < height)
    }
    
    /*
     return true if this ocean contains all the given coordinate points
     */
    func contains(_ points: Array<Coordinate>) ->Bool
    {
        return !points.contains(where:{!self.contains($0)})
    }
    
    /*
     return all the locations that will fit a certain length of contiguous locations on the ocean
     in either a horizontal or vertical orientation
     */
    func locationsThatFit(length: Int) -> [[Coordinate]] {
        var locations = [[Coordinate]]()
        
        //horizontal possible fits for each row
        for y in 0..<height {
            for start in 0...(width - length) {
                var span = [Coordinate]()
                for x in start..<(start + length) {
                    span.append(Coordinate(x: x, y: y))
                }
                locations.append(span)
            }
        }
        
        //vertical possible fits for each column
        for x in 0..<width {
            for start in 0...(height - length) {
                var span = [Coordinate]()
                for y in start..<(start + length) {
                    span.append(Coordinate(x:x, y:y))
                }
                locations.append(span)
            }
        }
        return locations
    }
}
