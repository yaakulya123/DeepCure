import Foundation
import SwiftUI
import Combine
import HealthKit

class DeepCureViewModel: ObservableObject {
    // Child models
    @Published var userModel = UserModel()
    @Published var appointmentModel = AppointmentModel()
    
    // Health data manager
    private let healthKitManager = HealthKitManager.shared
    
    // App state
    @Published var selectedTab = 0
    @Published var showingNotifications = false
    @Published var showingProfileSheet = false
    @Published var healthKitAuthorized = false
    @Published var showHealthConnectedBanner = false
    @Published var healthDataRefreshError: String?
    @Published var isRefreshingHealthData = false
    
    // Date-related info
    @Published var currentDate = Date()
    private var cancellables = Set<AnyCancellable>()
    private var dateTimer: Timer?
    private var healthDataRefreshTimer: Timer?
    
    // MARK: - Health Data Refresh Properties
    @Published var isRefreshingHealth = false
    @Published var lastHealthRefresh: Date? = nil
    @Published var healthDataError: String? = nil

    // MARK: - Initialization
    init() {
        // Set up timer to update current date every minute
        dateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
        }
        
        setupHealthKitBindings()
        requestHealthKitAuthorization()
        
        // Set up timer to refresh health data hourly
        healthDataRefreshTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.refreshHealthData()
        }
    }
    
    deinit {
        dateTimer?.invalidate()
        healthDataRefreshTimer?.invalidate()
    }
    
    // MARK: - Setup HealthKit Bindings
    private func setupHealthKitBindings() {
        // Heart rate data
        healthKitManager.$heartRate
            .sink { [weak self] value in
                self?.userModel.healthMetrics.averageHeartRate = Int(value)
                self?.userModel.healthMetrics.lastUpdated = Date()
            }
            .store(in: &cancellables)
            
        healthKitManager.$heartRateTrend
            .sink { [weak self] value in
                self?.userModel.healthMetrics.averageHeartRateTrend = Int(value)
            }
            .store(in: &cancellables)
            
        healthKitManager.$heartRateVariability
            .sink { [weak self] value in
                self?.userModel.healthMetrics.heartRateVariability = value
            }
            .store(in: &cancellables)
        
        // Sleep data
        healthKitManager.$sleepHours
            .sink { [weak self] value in
                self?.userModel.healthMetrics.sleepHours = value
            }
            .store(in: &cancellables)
            
        healthKitManager.$sleepHoursTrend
            .sink { [weak self] value in
                self?.userModel.healthMetrics.sleepHoursTrend = value
            }
            .store(in: &cancellables)
        
        // Activity data
        healthKitManager.$stepCount
            .sink { [weak self] value in
                self?.userModel.healthMetrics.stepCount = value
            }
            .store(in: &cancellables)
            
        healthKitManager.$stepCountTrend
            .sink { [weak self] value in
                self?.userModel.healthMetrics.stepCountTrend = Int(value)
            }
            .store(in: &cancellables)
            
        healthKitManager.$activeEnergyBurned
            .sink { [weak self] value in
                self?.userModel.healthMetrics.caloriesBurned = value
            }
            .store(in: &cancellables)
        
        // Blood pressure
        healthKitManager.$bloodPressureSystolic
            .sink { [weak self] value in
                self?.userModel.healthMetrics.systolicPressure = value
            }
            .store(in: &cancellables)
            
        healthKitManager.$bloodPressureDiastolic
            .sink { [weak self] value in
                self?.userModel.healthMetrics.diastolicPressure = value
            }
            .store(in: &cancellables)
        
        // Other vitals
        healthKitManager.$bloodOxygen
            .sink { [weak self] value in
                self?.userModel.healthMetrics.bloodOxygen = value
            }
            .store(in: &cancellables)
            
        healthKitManager.$respiratoryRate
            .sink { [weak self] value in
                self?.userModel.healthMetrics.respiratoryRate = value
            }
            .store(in: &cancellables)
            
        healthKitManager.$bodyTemperature
            .sink { [weak self] value in
                self?.userModel.healthMetrics.bodyTemperature = value
            }
            .store(in: &cancellables)
            
        // Authorization status
        healthKitManager.$isAuthorized
            .sink { [weak self] authorized in
                self?.healthKitAuthorized = authorized
                if authorized {
                    self?.userModel.healthKitStatus = .authorized
                    self?.showHealthConnectedBanner = true
                    
                    // Auto-hide banner after 5 seconds
                    let workItem = DispatchWorkItem {
                        self?.showHealthConnectedBanner = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
                }
            }
            .store(in: &cancellables)
        
        // Track loading state
        healthKitManager.$isLoading
            .sink { [weak self] isLoading in
                self?.isRefreshingHealthData = isLoading
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Health Data Management
    
    func requestHealthKitAuthorization() {
        // Show a loading indicator
        isRefreshingHealthData = true
        
        healthKitManager.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Authorization successful, now fetch specific health data
                    self?.userModel.healthKitStatus = .authorized
                    self?.healthKitAuthorized = true
                    
                    // When authorization is successful, immediately fetch data
                    self?.refreshHealthData()
                    
                    // Show connection successful banner
                    self?.showHealthConnectedBanner = true
                    
                    // Auto-hide banner after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self?.showHealthConnectedBanner = false
                    }
                } else if let error = error {
                    self?.healthDataError = "HealthKit authorization failed: \(error.localizedDescription)"
                    self?.userModel.healthKitStatus = .denied
                    self?.isRefreshingHealthData = false
                } else {
                    self?.userModel.healthKitStatus = .denied
                    self?.healthDataError = "HealthKit authorization denied by user"
                    self?.isRefreshingHealthData = false
                }
            }
        }
    }
    
    func refreshHealthData() {
        isRefreshingHealth = true
        healthDataError = nil
        
        // Show a loading indicator while fetching data
        isRefreshingHealthData = true
        
        // Use the updated fetchAllHealthData method with the completion handler
        healthKitManager.fetchAllHealthData { [weak self] result in
            DispatchQueue.main.async {
                self?.isRefreshingHealth = false
                self?.lastHealthRefresh = Date()
                self?.isRefreshingHealthData = false
                
                switch result {
                case .success(let metrics):
                    self?.userModel.healthMetrics = metrics
                    print("Successfully fetched health data: HR: \(metrics.averageHeartRate), Sleep: \(metrics.sleepHours) hours")
                    
                    // Log an activity about health data refresh
                    self?.logActivity(
                        icon: "heart.fill", 
                        color: .red, 
                        title: "Health Data Updated", 
                        description: "Latest health metrics retrieved from Apple Health"
                    )
                    
                case .failure(let error):
                    self?.healthDataError = "Failed to fetch health data: \(error.localizedDescription)"
                    print("Health data fetch error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Return current greeting based on time of day
    func currentGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        
        if hour < 12 {
            return "Good morning"
        } else if hour < 18 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }
    
    // Return formatted date for display
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
    
    // Go to a specific tab
    func navigateTo(tab: Int) {
        selectedTab = tab
    }
    
    // Log a new user activity
    func logActivity(icon: String, color: Color, title: String, description: String) {
        let newActivity = Activity(
            id: UUID(),
            icon: icon,
            color: color,
            title: title,
            description: description,
            timestamp: Date()
        )
        
        appointmentModel.addActivity(newActivity)
    }
    
    // Schedule a new appointment
    func scheduleAppointment(_ appointment: Appointment) {
        appointmentModel.addAppointment(appointment)
        
        // Also log this as an activity
        logActivity(
            icon: "calendar",
            color: .blue,
            title: "Appointment Scheduled",
            description: "\(appointment.doctorName) - \(appointment.specialty)"
        )
    }
}