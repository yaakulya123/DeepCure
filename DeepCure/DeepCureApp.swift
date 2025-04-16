//
//  DeepCureApp.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI
import HealthKit

@main
struct DeepCureApp: App {
    @StateObject private var viewModel = DeepCureViewModel()
    
    init() {
        // Enable HealthKit capability in the project settings for this to work
        print("HealthKit available: \(HKHealthStore.isHealthDataAvailable())")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
