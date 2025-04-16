//
//  ContentView.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DeepCureViewModel()
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            // Home Tab
            homeView
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Medical Transcription Tab
            MedicalTranscriptionViewWrapper()
                .tabItem {
                    Label("Transcribe", systemImage: "waveform")
                }
                .tag(1)
            
            // Medical Records Tab
            MedicalRecordsViewWrapper()
                .tabItem {
                    Label("Records", systemImage: "folder.fill")
                }
                .tag(2)
            
            // QR Health Profile Tab
            QRHealthProfileViewWrapper()
                .tabItem {
                    Label("Health QR", systemImage: "qrcode")
                }
                .tag(3)
            
            // AI Guidance Tab
            AIGuidanceViewWrapper()
                .tabItem {
                    Label("AI Guide", systemImage: "brain")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .environmentObject(viewModel)
    }
    
    // Enhanced home view with modern design
    var homeView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header section with profile and title
                    HStack {
                        Text("DeepCure")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.showingNotifications = true
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                                
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
                    
                    // Welcome message
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.currentGreeting() + ",")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text(viewModel.userModel.profile.name)
                            .font(.system(size: 24, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Health status summary
                    VStack(spacing: 0) {
                        HStack {
                            Text("Today's Health Summary")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.isRefreshingHealthData {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .padding(.trailing, 5)
                            }
                            
                            Button(action: {
                                viewModel.refreshHealthData()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            .disabled(viewModel.isRefreshingHealthData)
                            .padding(.trailing, 5)
                            
                            Text(viewModel.formattedDate())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        if let errorMessage = viewModel.healthDataRefreshError {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                                .padding(.top, 4)
                        }
                        
                        if !viewModel.healthKitAuthorized {
                            Button(action: {
                                viewModel.refreshHealthData()
                            }) {
                                HStack {
                                    Image(systemName: "heart.circle.fill")
                                        .foregroundColor(.red)
                                    Text("Connect Health Data")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            .padding(.top, 4)
                        }
                        
                        HStack(spacing: 15) {
                            // Medication adherence
                            HealthMetricCard(
                                icon: "pills.fill",
                                color: .green,
                                value: "\(viewModel.userModel.healthMetrics.medicationAdherence)%",
                                title: "Adherence",
                                trend: viewModel.userModel.healthMetrics.medicationAdherenceTrend > 0 ? 
                                       "+\(viewModel.userModel.healthMetrics.medicationAdherenceTrend)%" :
                                       "\(viewModel.userModel.healthMetrics.medicationAdherenceTrend)%"
                            )
                            
                            // Activity
                            HealthMetricCard(
                                icon: "heart.fill",
                                color: .red,
                                value: "\(viewModel.userModel.healthMetrics.averageHeartRate)",
                                title: "Avg HR",
                                trend: viewModel.userModel.healthMetrics.averageHeartRateTrend > 0 ?
                                       "+\(viewModel.userModel.healthMetrics.averageHeartRateTrend) bpm" :
                                       "\(viewModel.userModel.healthMetrics.averageHeartRateTrend) bpm"
                            )
                            
                            // Sleep
                            HealthMetricCard(
                                icon: "bed.double.fill",
                                color: .purple,
                                value: String(format: "%.1fh", viewModel.userModel.healthMetrics.sleepHours),
                                title: "Sleep",
                                trend: viewModel.userModel.healthMetrics.sleepHoursTrend > 0 ?
                                       "+\(String(format: "%.1fh", viewModel.userModel.healthMetrics.sleepHoursTrend))" :
                                       "\(String(format: "%.1fh", viewModel.userModel.healthMetrics.sleepHoursTrend))"
                            )
                        }
                        .padding()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // Upcoming appointments
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
                        
                        ForEach(viewModel.appointmentModel.upcomingAppointments(limit: 2)) { appointment in
                            AppointmentCard(appointment: appointment)
                        }
                        
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
                    
                    // Recent activities with improved design
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
                        
                        ForEach(viewModel.appointmentModel.recentActivities(limit: 3)) { activity in
                            HStack(spacing: 15) {
                                Image(systemName: activity.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(activity.color)
                                    .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(activity.title)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text(activity.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(activity.formattedTime())
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            
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
                    
                    // Quick actions section with modern design
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            QuickActionButton(
                                title: "Record",
                                systemName: "mic.fill",
                                color: .blue
                            ) {
                                viewModel.selectedTab = 1
                            }
                            
                            QuickActionButton(
                                title: "New Record",
                                systemName: "plus.rectangle.fill",
                                color: .green
                            ) {
                                viewModel.selectedTab = 2
                            }
                            
                            QuickActionButton(
                                title: "Health QR",
                                systemName: "qrcode",
                                color: .purple
                            ) {
                                viewModel.selectedTab = 3
                            }
                            
                            QuickActionButton(
                                title: "AI Guide",
                                systemName: "brain",
                                color: .orange
                            ) {
                                viewModel.selectedTab = 4
                            }
                            
                            QuickActionButton(
                                title: "Reminders",
                                systemName: "bell.fill",
                                color: Color(red: 0.2, green: 0.5, blue: 0.8)
                            ) {
                                addMedicationReminderAlert()
                            }
                            
                            QuickActionButton(
                                title: "Find Doctor",
                                systemName: "stethoscope",
                                color: Color(red: 0.6, green: 0.3, blue: 0.7)
                            ) {
                                // This will be implemented later
                                viewModel.logActivity(
                                    icon: "magnifyingglass",
                                    color: .blue,
                                    title: "Doctor Search",
                                    description: "Searched for doctors near you"
                                )
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
        .sheet(isPresented: $viewModel.showingProfileSheet) {
            ProfileView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showingNotifications) {
            NotificationsView()
                .environmentObject(viewModel)
        }
    }
    
    // Add a medication reminder demonstration
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

// Updated appointment card component to use the Appointment model
struct AppointmentCard: View {
    let appointment: Appointment
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "stethoscope")
                        .foregroundColor(.blue)
                )
            
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

// Health metric card component (unchanged)
struct HealthMetricCard: View {
    let icon: String
    let color: Color
    let value: String
    let title: String
    let trend: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(color)
                    .cornerRadius(10)
                
                Spacer()
                
                Text(trend)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(trend.hasPrefix("+") ? .green : .red)
            }
            
            HStack {
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

// Enhanced quick action button with improved visuals
struct QuickActionButton: View {
    var title: String
    var systemName: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(15)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
        }
    }
}

// Notifications view
struct NotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            VStack {
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
                    List {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        withAnimation {
                            viewModel.userModel.clearNotifications()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Notification row component
struct NotificationRow: View {
    let title: String
    let message: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .cornerRadius(10)
                .padding(.top, 2)
            
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

// Wrapper views to avoid redeclarations
struct MedicalTranscriptionViewWrapper: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            MedicalTranscriptionView()
                .environmentObject(viewModel)
        }
    }
}

struct MedicalRecordsViewWrapper: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            MedicalRecordsView()
                .environmentObject(viewModel)
        }
    }
}

struct QRHealthProfileViewWrapper: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            QRHealthProfileView()
                .environmentObject(viewModel)
        }
    }
}

struct AIGuidanceViewWrapper: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            AIGuidanceView()
                .environmentObject(viewModel)
        }
    }
}

// Updated profile view to use the user model data
struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        NavigationView {
            Form {
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
                    
                    let bmiData = viewModel.userModel.medicalProfile.formattedBMI()
                    HStack {
                        Text("BMI")
                        Spacer()
                        Text("\(bmiData.0, specifier: "%.1f") - \(bmiData.1)")
                            .foregroundColor(bmiData.2)
                    }
                    
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

// Medical details view
struct MedicalDetailsView: View {
    @EnvironmentObject var viewModel: DeepCureViewModel
    
    var body: some View {
        List {
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

#Preview {
    ContentView()
}
