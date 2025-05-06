//
//  ContentView.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI

/// `ContentView` is the main container view for the DeepCure application.
/// It provides the tab-based navigation structure and houses the primary
/// dashboard (home view) with health metrics, appointments, and activities.
struct ContentView: View {
    /// View model that maintains the app's state and business logic
    /// While we already have one passed through the environment from DeepCureApp,
    /// we create another instance here to ensure this view can work in isolation (e.g., in previews)
    @StateObject private var viewModel = DeepCureViewModel()
    
    var body: some View {
        // Main tab-based navigation interface
        TabView(selection: $viewModel.selectedTab) {
            // Home Tab - Dashboard with health metrics and activity summary
            homeView
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Medical Transcription Tab - Speech-to-text and medical term simplification
            MedicalTranscriptionViewWrapper()
                .tabItem {
                    Label("Transcribe", systemImage: "waveform")
                }
                .tag(1)
            
            // Medical Records Tab - Store and organize medical documents and data
            MedicalRecordsViewWrapper()
                .tabItem {
                    Label("Records", systemImage: "folder.fill")
                }
                .tag(2)
            
            // QR Health Profile Tab - Generate shareable health data QR codes
            QRHealthProfileViewWrapper()
                .tabItem {
                    Label("Health QR", systemImage: "qrcode")
                }
                .tag(3)
            
            // AI Guidance Tab - Medical AI assistant interface
            AIGuidanceViewWrapper()
                .tabItem {
                    Label("AI Guide", systemImage: "brain")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .environmentObject(viewModel)
    }
    
    // MARK: - Home Dashboard View
    
    /// The primary dashboard view showing user health information, appointments,
    /// and recent activity in a modern card-based interface
    var homeView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // MARK: Header Section
                    
                    // App title with notification and profile buttons
                    HStack {
                        Text("DeepCure")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        // Notification button with badge for unread count
                        Button(action: {
                            viewModel.showingNotifications = true
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                                
                                // Show notification count badge if there are unread notifications
                                if viewModel.userModel.notificationCount > 0 {
                                    Text("\(viewModel.userModel.notificationCount)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Profile button to access user settings and information
                        Button(action: {
                            viewModel.showingProfileSheet = true
                        }) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: Greeting Section
                    
                    // Personalized greeting based on time of day and user name
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.currentGreeting() + ",")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text(viewModel.userModel.profile.name)
                            .font(.system(size: 24, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // MARK: Health Data Section
                    
                    // Health metrics display with connectivity option
                    VStack(spacing: 0) {
                        HStack {
                            Text("Health Data")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Show loading indicator during health data refresh
                            if viewModel.isRefreshingHealthData {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .padding(.trailing, 5)
                            }
                            
                            // Manual refresh button for health data
                            Button(action: {
                                viewModel.refreshHealthData()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            .disabled(viewModel.isRefreshingHealthData)
                            .padding(.trailing, 5)
                            
                            // Last updated timestamp
                            Text(viewModel.formattedDate())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Show error message if health data retrieval failed
                        if let errorMessage = viewModel.healthDataError {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                                .padding(.top, 4)
                        }
                        
                        // MARK: Health Connection State
                        
                        // Show connection prompt if HealthKit is not yet authorized
                        if !viewModel.healthKitAuthorized {
                            VStack(spacing: 15) {
                                Text("Connect your Apple Health data")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                
                                Text("Get insights from your health data including heart rate, sleep, and medications")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                // Authorization request button
                                Button(action: {
                                    viewModel.requestHealthKitAuthorization()
                                }) {
                                    HStack {
                                        Image(systemName: "heart.circle.fill")
                                            .foregroundColor(.white)
                                        Text("Connect Health Data")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 20)
                        } else {
                            // MARK: Health Metrics Display
                            
                            // Display health metrics in card format when authorized
                            VStack(spacing: 15) {
                                // First row of health metrics: Heart rate and Sleep
                                HStack(spacing: 15) {
                                    // Heart rate card with trend indicator
                                    HealthMetricCard(
                                        icon: "heart.fill",
                                        color: .red,
                                        value: "\(viewModel.userModel.healthMetrics.averageHeartRate)",
                                        title: "BPM",
                                        trend: viewModel.userModel.healthMetrics.averageHeartRateTrend > 0 ?
                                            "+\(viewModel.userModel.healthMetrics.averageHeartRateTrend)" :
                                            "\(viewModel.userModel.healthMetrics.averageHeartRateTrend)"
                                    )
                                    
                                    // Sleep duration card with trend indicator
                                    HealthMetricCard(
                                        icon: "bed.double.fill",
                                        color: .purple,
                                        value: String(format: "%.1f", viewModel.userModel.healthMetrics.sleepHours),
                                        title: "Hours Sleep",
                                        trend: viewModel.userModel.healthMetrics.sleepHoursTrend > 0 ?
                                            "+\(String(format: "%.1f", viewModel.userModel.healthMetrics.sleepHoursTrend))" :
                                            "\(String(format: "%.1f", viewModel.userModel.healthMetrics.sleepHoursTrend))"
                                    )
                                }
                                .padding(.horizontal)
                                
                                // Second row of health metrics: Steps and Calories
                                HStack(spacing: 15) {
                                    // Daily steps card with trend indicator
                                    HealthMetricCard(
                                        icon: "figure.walk",
                                        color: .green,
                                        value: "\(viewModel.userModel.healthMetrics.stepCount)",
                                        title: "Steps",
                                        trend: viewModel.userModel.healthMetrics.stepCountTrend > 0 ?
                                            "+\(viewModel.userModel.healthMetrics.stepCountTrend)" :
                                            "\(viewModel.userModel.healthMetrics.stepCountTrend)"
                                    )
                                    
                                    // Calories burned card
                                    HealthMetricCard(
                                        icon: "flame.fill",
                                        color: .orange,
                                        value: "\(Int(viewModel.userModel.healthMetrics.caloriesBurned))",
                                        title: "Calories",
                                        trend: ""
                                    )
                                }
                                .padding(.horizontal)
                                
                                // Last update timestamp using relative formatting
                                if let lastRefresh = viewModel.lastHealthRefresh {
                                    // Create the formatted string first to avoid buildExpression error
                                    let timeString = {
                                        let formatter = RelativeDateTimeFormatter()
                                        formatter.unitsStyle = .abbreviated
                                        return formatter.localizedString(for: lastRefresh, relativeTo: Date())
                                    }()
                                    
                                    Text("Last updated " + timeString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 8)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // MARK: Appointments Section
                    
                    // Upcoming appointments card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Upcoming Appointments")
                                .font(.headline)
                            Spacer()
                            Button("See All") {
                                // Navigate to full appointments list
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        
                        // Show up to 2 upcoming appointments
                        ForEach(viewModel.appointmentModel.upcomingAppointments(limit: 2)) { appointment in
                            AppointmentCard(appointment: appointment)
                        }
                        
                        // Show placeholder when no appointments are scheduled
                        if viewModel.appointmentModel.upcomingAppointments().isEmpty {
                            Text("No upcoming appointments")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // MARK: Recent Activities Section
                    
                    // Recent health-related activities timeline
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Activities")
                                .font(.headline)
                            Spacer()
                            Button("View All") {
                                // Navigate to all activities
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        
                        // Show the 3 most recent activities
                        ForEach(viewModel.appointmentModel.recentActivities(limit: 3)) { activity in
                            HStack(spacing: 15) {
                                // Activity icon with color coding
                                Image(systemName: activity.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(activity.color)
                                    .cornerRadius(12)
                                
                                // Activity details
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(activity.title)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text(activity.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Relative time indicator (e.g., "2h ago")
                                Text(activity.formattedTime())
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            
                            // Add divider between activities, but not after the last one
                            if activity.id != viewModel.appointmentModel.recentActivities(limit: 3).last?.id {
                                Divider()
                                    .padding(.leading, 55)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // MARK: Quick Actions Section
                    
                    // Grid of shortcut buttons to key app features
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // 3-column grid of action buttons
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            // Medical transcription shortcut
                            QuickActionButton(
                                title: "Record",
                                systemName: "mic.fill",
                                color: .blue
                            ) {
                                viewModel.selectedTab = 1
                            }
                            
                            // New medical record shortcut
                            QuickActionButton(
                                title: "New Record",
                                systemName: "plus.rectangle.fill",
                                color: .green
                            ) {
                                viewModel.selectedTab = 2
                            }
                            
                            // AI medical guidance shortcut
                            QuickActionButton(
                                title: "AI Guide",
                                systemName: "brain",
                                color: .orange
                            ) {
                                viewModel.selectedTab = 4
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
        }
        // MARK: Modal Sheets
        .sheet(isPresented: $viewModel.showingProfileSheet) {
            // User profile and settings sheet
            ProfileView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showingNotifications) {
            // Notifications list sheet
            NotificationsView()
                .environmentObject(viewModel)
        }
    }
    
    /// Demonstrates adding a medication reminder (placeholder function)
    /// In a real app implementation, this would present a form to create actual reminders
    func addMedicationReminderAlert() {
        // In a real app, this would show a form to create reminders
        // For now, let's simulate adding a reminder
        viewModel.logActivity(
            icon: "bell.fill", 
            color: .blue,
            title: "Medication Reminder Added", 
            description: "Lisinopril 10mg - Daily at 8:00 AM"
        )
    }
}

// MARK: - Supporting UI Components

/// Card component for displaying doctor appointment information
struct AppointmentCard: View {
    /// The appointment data to display
    let appointment: Appointment
    
    var body: some View {
        HStack(spacing: 15) {
            // Doctor icon with background
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "stethoscope")
                        .foregroundColor(.blue)
                )
            
            // Appointment details: doctor name, specialty, and date
            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.doctorName)
                    .font(.system(size: 16, weight: .medium))
                
                Text(appointment.specialty)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(appointment.formattedDate())
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Appointment type badge (virtual or in-person)
            HStack {
                if appointment.isVirtual {
                    Text("Virtual")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green)
                        .cornerRadius(8)
                } else {
                    Text("In-person")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

/// Card component for displaying health metrics with trend indicators
struct HealthMetricCard: View {
    /// System name of the SF Symbol icon to display
    let icon: String
    
    /// Background color for the icon
    let color: Color
    
    /// The primary metric value to display (e.g., "72" for heart rate)
    let value: String
    
    /// Label describing the metric (e.g., "BPM")
    let title: String
    
    /// Trend indicator showing change (e.g., "+5" or "-2")
    let trend: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                // Metric icon with colored background
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(color)
                    .cornerRadius(10)
                
                Spacer()
                
                // Trend indicator with color coding (green for positive, red for negative)
                Text(trend)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(trend.hasPrefix("+") ? .green : .red)
            }
            
            HStack {
                // Main metric value and label
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold))
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

/// Button component for quick access to app features
struct QuickActionButton: View {
    /// Button label text
    var title: String
    
    /// System name of the SF Symbol icon to display
    var systemName: String
    
    /// Background color for the icon
    var color: Color
    
    /// Action to perform when button is tapped
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon with colored background
                Image(systemName: systemName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(15)
                
                // Button label
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Modal Views

/// View for displaying user notifications
struct NotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Empty state when no notifications exist
                if viewModel.userModel.notificationCount == 0 {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 70))
                            .foregroundColor(.gray)
                        
                        Text("No New Notifications")
                            .font(.title2)
                        
                        Text("You're all caught up!")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                } else {
                    // List of notification items when notifications exist
                    List {
                        // Sample notification items - in a real app these would come from a data source
                        NotificationRow(
                            title: "Appointment Reminder",
                            message: "You have an appointment with Dr. Emily Chen tomorrow at 10:30 AM",
                            time: "Just now",
                            icon: "calendar",
                            color: .blue
                        )
                        
                        NotificationRow(
                            title: "Medication Reminder",
                            message: "Time to take Lisinopril 10mg",
                            time: "10 minutes ago",
                            icon: "pills",
                            color: .purple
                        )
                        
                        NotificationRow(
                            title: "Lab Results Available",
                            message: "Your recent blood test results are ready to view",
                            time: "2 hours ago",
                            icon: "cross",
                            color: .red
                        )
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                // Clear all notifications button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        withAnimation {
                            viewModel.userModel.clearNotifications()
                        }
                    }
                }
                
                // Dismiss sheet button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

/// Row component for displaying a single notification
struct NotificationRow: View {
    /// Notification title
    let title: String
    
    /// Notification message content
    let message: String
    
    /// Relative time (e.g., "2 hours ago")
    let time: String
    
    /// System name of the SF Symbol icon to display
    let icon: String
    
    /// Background color for the icon
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Notification type icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .cornerRadius(10)
                .padding(.top, 2)
            
            // Notification content and timestamp
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(time)
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary.opacity(0.7))
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Navigation Wrapper Views

/// Wrapper for MedicalTranscriptionView to provide navigation and environment objects
struct MedicalTranscriptionViewWrapper: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            MedicalTranscriptionView()
                .environmentObject(viewModel)
        }
    }
}

/// Wrapper for MedicalRecordsView to provide navigation and environment objects
struct MedicalRecordsViewWrapper: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            MedicalRecordsView()
                .environmentObject(viewModel)
        }
    }
}

/// Wrapper for QRHealthProfileView to provide navigation and environment objects
struct QRHealthProfileViewWrapper: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            QRHealthProfileView()
                .environmentObject(viewModel)
        }
    }
}

/// Wrapper for AIGuidanceView to provide navigation and environment objects
struct AIGuidanceViewWrapper: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            AIGuidanceView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - User Profile Views

/// View for displaying and editing user profile information
struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: Profile Header
                
                // User avatar and basic identity information
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                                .padding(.bottom, 5)
                            Text(viewModel.userModel.profile.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Member since \(Calendar.current.component(.year, from: viewModel.userModel.profile.memberSince))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                }
                
                // MARK: Personal Information Section
                
                // Contact details and basic biographical information
                Section(header: Text("Personal Information")) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(viewModel.userModel.profile.email)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Phone")
                        Spacer()
                        Text(viewModel.userModel.profile.phoneNumber)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Date of Birth")
                        Spacer()
                        Text(viewModel.userModel.profile.formattedDateOfBirth())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Age")
                        Spacer()
                        Text("\(viewModel.userModel.profile.age()) years")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: Medical Information Section
                
                // User's basic medical information
                Section(header: Text("Medical Information")) {
                    HStack {
                        Text("Blood Type")
                        Spacer()
                        Text(viewModel.userModel.medicalProfile.bloodType)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        Text("\(Int(viewModel.userModel.medicalProfile.height)) cm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(Int(viewModel.userModel.medicalProfile.weight)) kg")
                            .foregroundColor(.secondary)
                    }
                    
                    // BMI with color-coded category
                    let bmiData = viewModel.userModel.medicalProfile.formattedBMI()
                    HStack {
                        Text("BMI")
                        Spacer()
                        Text("\(bmiData.0, specifier: "%.1f") - \(bmiData.1)")
                            .foregroundColor(bmiData.2)
                    }
                    
                    // Links to detailed medical information
                    NavigationLink {
                        MedicalDetailsView()
                            .environmentObject(viewModel)
                    } label: {
                        Text("Medical Details")
                    }
                    
                    NavigationLink(destination: Text("Insurance Details")) {
                        Text("Insurance Details")
                    }
                    
                    NavigationLink(destination: Text("Emergency Contacts")) {
                        Text("Emergency Contacts")
                    }
                }
                
                // MARK: Account Actions
                
                // Sign out and other account management options
                Section {
                    Button(action: {
                        // Sign out logic would go here
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

/// Detailed view of user's medical information
struct MedicalDetailsView: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        List {
            // MARK: Allergies Section
            Section(header: Text("Allergies")) {
                if viewModel.userModel.medicalProfile.allergies.isEmpty {
                    Text("No allergies recorded")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.userModel.medicalProfile.allergies, id: \.self) { allergy in
                        Text(allergy)
                    }
                }
            }
            
            // MARK: Chronic Conditions Section
            Section(header: Text("Chronic Conditions")) {
                if viewModel.userModel.medicalProfile.chronicConditions.isEmpty {
                    Text("No chronic conditions recorded")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.userModel.medicalProfile.chronicConditions, id: \.self) { condition in
                        Text(condition)
                    }
                }
            }
            
            // MARK: Medications Section
            Section(header: Text("Current Medications")) {
                if viewModel.userModel.medicalProfile.currentMedications.isEmpty {
                    Text("No medications recorded")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.userModel.medicalProfile.currentMedications) { medication in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(medication.name)
                                .font(.headline)
                            Text("\(medication.dosage) - \(medication.frequency)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Purpose: \(medication.purpose)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Medical Details")
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
