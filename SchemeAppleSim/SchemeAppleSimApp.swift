//
//  SchemeAppleSimApp.swift
//  SchemeAppleSim
//
//  Created by Tibo Stans on 03/10/2025.
//

import SwiftUI

@main
struct SchemeAppleSimApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 700)
        #endif
        #if os(iOS)
        .windowResizability(.automatic)
        #endif
    }
}
