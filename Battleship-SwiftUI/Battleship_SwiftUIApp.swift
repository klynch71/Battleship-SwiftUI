//
//  Game.swift
//  Battleship-SwiftUI
//
//  Created by Sebastian Kucera on 11/20/22.
//


import SwiftUI

@main
struct Battleship_SwiftUIApp: App {
    @StateObject private var game = Game(numCols: 8, numRows: 8)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
        }
    }
}
