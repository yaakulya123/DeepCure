//
//  DeepCureApp.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI
import HealthKit

/// @main marks this struct as the entry point for the application
/// The DeepCureApp class serves as the main application structure and entry point
@main
struct DeepCureApp: App {
    /// Create a single shared instance of the view model that will be passed down to all views
    /// Using @StateObject ensures this instance persists throughout the app lifecycle
    @StateObject private var viewModel = DeepCureViewModel()
    
    init() {
        // Check HealthKit availability on this device
        // This verification is important as HealthKit is not available on all devices (e.g., iPad)
        // Enable HealthKit capability in the project settings for this to work
        print("HealthKit available: \(HKHealthStore.isHealthDataAvailable())")
        
        // Note: Additional app-wide configuration can be done here, such as:
        // - Setting up Firebase configuration
        // - Configuring app appearance
        // - Initializing analytics services
    }
    
    /// The scene builder that defines the app's window structure and initial content view
    var body: some Scene {
        WindowGroup {
            // ContentView is the main root view that handles tab-based navigation
            ContentView()
                // Make the view model available to all child views in the hierarchy
                .environmentObject(viewModel)
        }
    }
}
