//
//  LaunchAtLogin.swift
//  TimeBuddy
//
//  Created by ke Liu on 8/6/25.
//

import SwiftUI
import ServiceManagement

@Observable
class AppState {
    var launchAtLogin = false
}


struct LaunchAtLoginSettingsSection: View {
    @Environment(AppState.self) var appState
    @Environment(\.appearsActive) var appearsActive
    
    var body: some View {
        @Bindable var appState = appState
        
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Launch at login", isOn: $appState.launchAtLogin)
            }
        }
        .onChange(of: appState.launchAtLogin) { _, newValue in
            if newValue == true {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
        .onChange(of: appearsActive) { _, newValue in
            guard newValue else { return }
            if SMAppService.mainApp.status == .enabled {
                appState.launchAtLogin = true
            } else {
                appState.launchAtLogin = false
            }
        }
        .onAppear {
            if SMAppService.mainApp.status == .enabled {
                appState.launchAtLogin = true
            } else {
                appState.launchAtLogin = false
            }
        }
    }
}



