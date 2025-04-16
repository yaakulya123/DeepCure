import Foundation
import SwiftUI
import Combine

// Main user model to store user information
class UserModel: ObservableObject {
    @Published var profile: UserProfile = UserProfile(
        id: UUID(),
        name: "John Doe",
        email: "john.doe@example.com",
        phoneNumber: "(123) 456-7890",
        dateOfBirth: Date(timeIntervalSince1970: 326937600), // May 15, 1980
        profileImage: nil,
        memberSince: Date(timeIntervalSince1970: 1735689600) // Jan 1, 2025
    )
    
    @Published var medicalProfile: MedicalProfile = MedicalProfile(
        bloodType: "O+",
        height: 175.0, // cm
        weight: 72.0,  // kg
        allergies: ["Penicillin", "Peanuts"],
        chronicConditions: ["Hypertension"],
        currentMedications: [
            Medication(name: "Lisinopril", dosage: "10mg", frequency: "Once daily", purpose: "Hypertension"),
            Medication(name: "Atorvastatin", dosage: "40mg", frequency: "Once daily at night", purpose: "Cholesterol")
        ]
    )
    
    @Published var healthMetrics: HealthMetrics = HealthMetrics()
    @Published var notificationCount: Int = 3
    @Published var healthKitStatus: HealthKitStatus = .notRequested
    
    // Method to update user profile
    func updateUserProfile(profile: UserProfile) {
        self.profile = profile
        // In a real app, this would sync with backend
    }
    
    // Method to update medical profile
    func updateMedicalProfile(medicalProfile: MedicalProfile) {
        self.medicalProfile = medicalProfile
        // In a real app, this would sync with backend
    }
    
    // Method to mark notifications as read
    func clearNotifications() {
        notificationCount = 0
        // In a real app, this would sync with backend
    }
}

// User's personal profile information
struct UserProfile: Identifiable, Codable {
    var id: UUID
    var name: String
    var email: String
    var phoneNumber: String
    var dateOfBirth: Date
    var profileImage: Data?
    var memberSince: Date
    var emergencyContacts: [EmergencyContact] = []
    
    // Format date of birth to string
    func formattedDateOfBirth() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateOfBirth)
    }
    
    // Calculate age based on date of birth
    func age() -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
}

// Emergency contact information
struct EmergencyContact: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var relationship: String
    var phoneNumber: String
}

// User's medical profile
struct MedicalProfile: Codable {
    var bloodType: String
    var height: Double // in cm
    var weight: Double // in kg
    var allergies: [String]
    var chronicConditions: [String]
    var currentMedications: [Medication]
    var insuranceProvider: String = "HealthPlus Insurance"
    var insuranceID: String = "HP-98765432"
    var primaryPhysician: String = "Dr. Robert Miller"
    
    // Calculate BMI
    func bmi() -> Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    // Format BMI with category
    func formattedBMI() -> (Double, String, Color) {
        let bmiValue = bmi()
        var category = ""
        var color = Color.black
        
        switch bmiValue {
        case ..<18.5:
            category = "Underweight"
            color = Color.orange
        case 18.5..<25:
            category = "Normal"
            color = Color.green
        case 25..<30:
            category = "Overweight"
            color = Color.yellow
        default:
            category = "Obese"
            color = Color.red
        }
        
        return (Double(round(10 * bmiValue) / 10), category, color)
    }
}

// Medication information
struct Medication: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var dosage: String
    var frequency: String
    var purpose: String
    var startDate: Date = Date().addingTimeInterval(-30 * 24 * 3600) // 30 days ago by default
    var endDate: Date? = nil
    var instructions: String = "Take with food"
    var refillDate: Date? = Date().addingTimeInterval(15 * 24 * 3600) // 15 days from now
    var pharmacy: String = "MediCare Pharmacy"
}

// HealthKit authorization status
enum HealthKitStatus {
    case notRequested
    case requested
    case authorized
    case denied
}

// User's current health metrics
struct HealthMetrics {
    // Defaults for when HealthKit data isn't available
    var medicationAdherence: Int = 92
    var medicationAdherenceTrend: Int = 5
    
    // Heart measurements
    var averageHeartRate: Int = 67
    var averageHeartRateTrend: Int = -3
    var heartRateVariability: Double = 45.0
    
    // Sleep data
    var sleepHours: Double = 7.5
    var sleepHoursTrend: Double = 0.5
    
    // Activity data
    var stepCount: Int = 7500
    var stepCountTrend: Int = 500
    var caloriesBurned: Double = 320.0
    
    // Blood pressure
    var systolicPressure: Double = 120.0
    var diastolicPressure: Double = 80.0
    
    // Other vitals
    var bloodOxygen: Double = 98.0
    var respiratoryRate: Double = 14.0
    var bodyTemperature: Double = 36.6
    
    var lastUpdated: Date = Date()
    
    // Format functions for displaying metrics
    func formattedHeartRate() -> String {
        return "\(averageHeartRate) bpm"
    }
    
    func formattedSleepHours() -> String {
        let hours = Int(sleepHours)
        let minutes = Int((sleepHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    func formattedBloodPressure() -> String {
        return "\(Int(systolicPressure))/\(Int(diastolicPressure))"
    }
    
    func formattedBloodOxygen() -> String {
        return "\(Int(bloodOxygen))%"
    }
}