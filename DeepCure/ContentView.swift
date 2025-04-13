//
//  ContentView.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingProfileSheet = false
    @State private var notificationCount = 3
    
    var body: some View {
        TabView(selection: $selectedTab) {
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
                            // Show notifications
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                                
                                if notificationCount > 0 {
                                    Text("\(notificationCount)")
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
                            showingProfileSheet = true
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
                        Text("Good morning,")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("John Doe")
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
                            
                            Text("Apr 12, 2025")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        HStack(spacing: 15) {
                            // Medication adherence
                            HealthMetricCard(
                                icon: "pills.fill",
                                color: .green,
                                value: "92%",
                                title: "Adherence",
                                trend: "+5%"
                            )
                            
                            // Activity
                            HealthMetricCard(
                                icon: "heart.fill",
                                color: .red,
                                value: "67",
                                title: "Avg HR",
                                trend: "-3 bpm"
                            )
                            
                            // Sleep
                            HealthMetricCard(
                                icon: "bed.double.fill",
                                color: .purple,
                                value: "7.5h",
                                title: "Sleep",
                                trend: "+0.5h"
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
                        
                        AppointmentCard(
                            doctorName: "Dr. Emily Chen",
                            specialty: "Cardiologist",
                            date: "Tomorrow, 10:30 AM",
                            isVirtual: true
                        )
                        
                        AppointmentCard(
                            doctorName: "Dr. Robert Miller",
                            specialty: "General Practitioner",
                            date: "Apr 22, 9:00 AM",
                            isVirtual: false
                        )
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
                        
                        ForEach(recentActivities, id: \.title) { activity in
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
                                
                                Text(activity.time)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            
                            if activity.title != recentActivities.last?.title {
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
                                selectedTab = 1
                            }
                            
                            QuickActionButton(
                                title: "New Record",
                                systemName: "plus.rectangle.fill",
                                color: .green
                            ) {
                                selectedTab = 2
                            }
                            
                            QuickActionButton(
                                title: "Health QR",
                                systemName: "qrcode",
                                color: .purple
                            ) {
                                selectedTab = 3
                            }
                            
                            QuickActionButton(
                                title: "Symptoms",
                                systemName: "waveform.path.ecg",
                                color: .orange
                            ) {
                                selectedTab = 4
                            }
                            
                            QuickActionButton(
                                title: "Reminders",
                                systemName: "bell.fill",
                                color: Color(red: 0.2, green: 0.5, blue: 0.8)
                            ) {
                                // Navigate to reminders
                            }
                            
                            QuickActionButton(
                                title: "Find Doctor",
                                systemName: "stethoscope",
                                color: Color(red: 0.6, green: 0.3, blue: 0.7)
                            ) {
                                // Navigate to doctor search
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
        .sheet(isPresented: $showingProfileSheet) {
            ProfileView()
        }
    }
    
    // Sample activities data
    var recentActivities: [Activity] = [
        Activity(
            icon: "heart.text.square.fill",
            color: .red,
            title: "Blood Test Results",
            description: "Cholesterol report from City Hospital",
            time: "Today"
        ),
        Activity(
            icon: "pills.fill",
            color: .blue,
            title: "Medication Reminder",
            description: "Took Lisinopril 10mg",
            time: "Yesterday"
        ),
        Activity(
            icon: "person.fill",
            color: .green,
            title: "Doctor's Appointment",
            description: "Dr. Johnson - Follow-up consultation",
            time: "Apr 10"
        )
    ]
}

// Activity model
struct Activity {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let time: String
}

// Health metric card component
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

// Appointment card component
struct AppointmentCard: View {
    let doctorName: String
    let specialty: String
    let date: String
    let isVirtual: Bool
    
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
                Text(doctorName)
                    .font(.system(size: 16, weight: .medium))
                
                Text(specialty)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(date)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                if isVirtual {
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

// Wrapper views to avoid redeclarations
struct MedicalTranscriptionViewWrapper: View {
    var body: some View {
        NavigationView {
            MedicalTranscriptionView()
        }
    }
}

struct MedicalRecordsViewWrapper: View {
    var body: some View {
        NavigationView {
            MedicalRecordsView()
        }
    }
}

struct QRHealthProfileViewWrapper: View {
    var body: some View {
        NavigationView {
            QRHealthProfileView()
        }
    }
}

struct AIGuidanceViewWrapper: View {
    var body: some View {
        NavigationView {
            AIGuidanceView()
        }
    }
}

// Simple profile view
struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
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
                            Text("John Doe")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Member since 2025")
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
                        Text("john.doe@example.com")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Phone")
                        Spacer()
                        Text("(123) 456-7890")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Date of Birth")
                        Spacer()
                        Text("May 15, 1980")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Medical Information")) {
                    NavigationLink(destination: Text("Medical History")) {
                        Text("Medical History")
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

#Preview {
    ContentView()
}
