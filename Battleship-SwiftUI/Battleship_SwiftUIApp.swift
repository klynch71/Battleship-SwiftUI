//
//  Battleship_SwiftUIApp.swift
//  Battleship-SwiftUI
//
//  Created by Kevin Lynch on 7/25/22.
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
