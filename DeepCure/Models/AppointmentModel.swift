import Foundation
import SwiftUI
import Combine

class AppointmentModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var activities: [Activity] = []
    
    init() {
        // Initialize with empty data
    }
    
    // Add a new appointment
    func addAppointment(_ appointment: Appointment) {
        appointments.append(appointment)
        // Sort appointments by date (soonest first)
        appointments.sort { $0.dateTime < $1.dateTime }
    }
    
    // Remove an appointment
    func removeAppointment(withID id: UUID) {
        appointments.removeAll { $0.id == id }
    }
    
    // Update an existing appointment
    func updateAppointment(_ appointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
            // Re-sort appointments by date
            appointments.sort { $0.dateTime < $1.dateTime }
        }
    }
    
    // Add a new activity
    func addActivity(_ activity: Activity) {
        activities.insert(activity, at: 0) // Add to the beginning (most recent)
        
        // Keep only the 20 most recent activities
        if activities.count > 20 {
            activities = Array(activities.prefix(20))
        }
    }
    
    // Get upcoming appointments
    func upcomingAppointments(limit: Int = 5) -> [Appointment] {
        let now = Date()
        let upcoming = appointments.filter { $0.dateTime > now }
        return Array(upcoming.prefix(limit))
    }
    
    // Get recent activities
    func recentActivities(limit: Int = 5) -> [Activity] {
        return Array(activities.prefix(limit))
    }
}

// Appointment model
struct Appointment: Identifiable, Codable {
    var id: UUID
    var doctorName: String
    var specialty: String
    var dateTime: Date
    var duration: Int // in minutes
    var isVirtual: Bool
    var location: String
    var notes: String
    var reminderSet: Bool = true
    
    // Format date for display
    func formattedDate() -> String {
        let formatter = DateFormatter()
        
        // If appointment is tomorrow, show "Tomorrow" instead of the date
        let calendar = Calendar.current
        if calendar.isDateInTomorrow(dateTime) {
            return "Tomorrow, \(formattedTime())"
        }
        
        // If appointment is within a week, show day of week
        if let daysFromNow = calendar.dateComponents([.day], from: Date(), to: dateTime).day, daysFromNow < 7 {
            formatter.dateFormat = "EEEE" // Day of week (e.g., "Monday")
            return "\(formatter.string(from: dateTime)), \(formattedTime())"
        }
        
        // Otherwise show month and day
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: dateTime)), \(formattedTime())"
    }
    
    // Format time for display
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: dateTime)
    }
}

// Activity model with Identifiable
struct Activity: Identifiable {
    var id: UUID
    var icon: String
    var color: Color
    var title: String
    var description: String
    var timestamp: Date
    
    // Format time for display
    func formattedTime() -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(timestamp) {
            return "Today"
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: timestamp, to: Date()).day, daysAgo < 7 {
            formatter.dateFormat = "EEEE" // Day of week
            return formatter.string(from: timestamp)
        } else {
            formatter.dateFormat = "MMM d" // Month and day
            return formatter.string(from: timestamp)
        }
    }
}