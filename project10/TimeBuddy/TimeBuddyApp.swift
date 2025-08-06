//
//  TimeBuddyApp.swift
//  TimeBuddy
//
//  Created by Paul Hudson on 14/04/2022.
//

import SwiftUI

@main
struct TimeBuddyApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("Time Buddy", systemImage: "clock") {
            ContentView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
