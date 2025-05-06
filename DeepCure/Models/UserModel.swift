import Foundation
import SwiftUI
import Combine

// Main user model to store user information
class UserModel: ObservableObject {
    @Published var profile: UserProfile = UserProfile(
        id: UUID(),
        name: "",
        email: "",
        phoneNumber: "",
        dateOfBirth: Date(),
        profileImage: nil,
        memberSince: Date()
    )
    
    @Published var medicalProfile: MedicalProfile = MedicalProfile(
        bloodType: "",
        height: 0.0,
        weight: 0.0,
        allergies: [],
        chronicConditions: [],
        currentMedications: []
    )
    
    @Published var healthMetrics: HealthMetrics = HealthMetrics()
    @Published var notificationCount: Int = 0
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
    var insuranceProvider: String = ""
    var insuranceID: String = ""
    var primaryPhysician: String = ""
    
    // Calculate BMI
    func bmi() -> Double {
        if height <= 0 { return 0 }
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
    var startDate: Date = Date()
    var endDate: Date? = nil
    var instructions: String = ""
    var refillDate: Date? = nil
    var pharmacy: String = ""
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
    // All metrics start with default empty values
    var medicationAdherence: Int = 0
    var medicationAdherenceTrend: Int = 0
    
    // Heart measurements
    var averageHeartRate: Int = 0
    var averageHeartRateTrend: Int = 0
    var heartRateVariability: Double = 0.0
    
    // Sleep data
    var sleepHours: Double = 0.0
    var sleepHoursTrend: Double = 0.0
    
    // Activity data
    var stepCount: Int = 0
    var stepCountTrend: Int = 0
    var caloriesBurned: Double = 0.0
    
    // Blood pressure
    var systolicPressure: Double = 0.0
    var diastolicPressure: Double = 0.0
    
    // Other vitals
    var bloodOxygen: Double = 0.0
    var respiratoryRate: Double = 0.0
    var bodyTemperature: Double = 0.0
    
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