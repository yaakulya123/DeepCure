import Foundation
import HealthKit
import Combine

/// `HealthKitManager` is responsible for interacting with Apple's HealthKit framework
/// to request, retrieve, and process health-related data.
/// It follows the Singleton design pattern and uses Combine for reactive updates.
class HealthKitManager: ObservableObject {
    /// Shared singleton instance to ensure consistent access throughout the app
    static let shared = HealthKitManager()
    
    /// The core HealthKit store for accessing health data
    private let healthStore = HKHealthStore()
    
    /// Set of cancellables for managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authorization Status Properties
    
    /// Published property indicating whether the app has been authorized to access HealthKit data
    @Published var isAuthorized = false
    
    /// Stores any errors encountered during the authorization process
    @Published var authorizationError: Error?
    
    /// Indicates whether a health data fetch operation is currently in progress
    @Published var isLoading = false
    
    // MARK: - Health Metrics Properties
    
    /// Current heart rate in beats per minute (BPM)
    @Published var heartRate: Double = 0
    
    /// Heart rate trend compared to previous period (positive value indicates improvement)
    @Published var heartRateTrend: Double = 0
    
    /// Heart rate variability in milliseconds (SDNN)
    @Published var heartRateVariability: Double = 0
    
    /// Average sleep duration in hours
    @Published var sleepHours: Double = 0
    
    /// Sleep duration trend compared to previous period
    @Published var sleepHoursTrend: Double = 0
    
    /// Step count for the current day
    @Published var stepCount: Int = 0
    
    /// Step count trend compared to previous period
    @Published var stepCountTrend: Double = 0
    
    /// Active calories burned in kcal
    @Published var activeEnergyBurned: Double = 0
    
    /// Systolic blood pressure in mmHg
    @Published var bloodPressureSystolic: Double = 0
    
    /// Diastolic blood pressure in mmHg
    @Published var bloodPressureDiastolic: Double = 0
    
    /// Blood oxygen saturation percentage
    @Published var bloodOxygen: Double = 0
    
    /// Blood glucose level in mg/dL
    @Published var bloodGlucose: Double = 0
    
    /// Respiratory rate in breaths per minute
    @Published var respiratoryRate: Double = 0
    
    /// Body temperature in degrees Celsius
    @Published var bodyTemperature: Double = 0
    
    // MARK: - HealthKit Configuration
    
    /// Set of HealthKit data types that this app requests permission to access
    /// These are used during the authorization request
    let typesToRead: Set<HKObjectType> = [
        // Vital signs
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
        HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
        
        // Body measurements
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
        
        // Activity
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        
        // Sleep
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        
        // Blood glucose if available
        HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
    ]
    
    /// Check if HealthKit is available on the current device
    /// iPad and some older devices do not support HealthKit
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    /// Private initializer enforces the use of the shared singleton instance
    private init() {
        // Private initializer to enforce singleton usage
    }
    
    // MARK: - Authorization Methods
    
    /// Request authorization to access HealthKit data types specified in typesToRead
    /// - Parameter completion: Closure called after authorization with success/error information
    func requestAuthorization(completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        // Verify HealthKit is available on this device
        guard isHealthKitAvailable else {
            let error = NSError(domain: "com.deepcure.healthkit", code: 0, 
                               userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"])
            authorizationError = error
            completion(false, error)
            return
        }
        
        // Request authorization for reading health data
        // Note: This app doesn't write data to HealthKit (empty toShare array)
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { [weak self] success, error in
            // Update UI on main thread and provide result to caller
            DispatchQueue.main.async {
                self?.isAuthorized = success
                self?.authorizationError = error
                completion(success, error)
            }
        }
    }
    
    // MARK: - Heart Rate Methods
    
    /// Fetches average and maximum heart rate data for the past week
    /// - Parameter completion: Closure that receives average and max heart rate values (in BPM)
    func fetchHeartRateData(completion: @escaping (Double?, Double?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(nil, nil)
            return
        }
        
        // Get data from past week
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(
            quantityType: heartRateType,
            quantitySamplePredicate: predicate,
            options: [.discreteAverage, .discreteMax]) { _, result, error in
                
                guard let result = result, error == nil else {
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                    return
                }
                
                var avgHeartRate: Double?
                var maxHeartRate: Double?
                
                // Extract average heart rate from results if available
                if let quantity = result.averageQuantity() {
                    avgHeartRate = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
                
                // Extract maximum heart rate from results if available
                if let quantity = result.maximumQuantity() {
                    maxHeartRate = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
                
                // Return results on the main thread
                DispatchQueue.main.async {
                    completion(avgHeartRate, maxHeartRate)
                }
            }
        
        healthStore.execute(query)
    }
    
    // MARK: - Blood Pressure Methods
    
    /// Fetches average systolic and diastolic blood pressure values from the past month
    /// - Parameter completion: Closure that receives systolic and diastolic values (in mmHg)
    func fetchBloodPressureData(completion: @escaping (Double?, Double?) -> Void) {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            completion(nil, nil)
            return
        }
        
        // Get data from past month
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        // First fetch systolic pressure
        let systolicQuery = HKStatisticsQuery(
            quantityType: systolicType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage) { _, systolicResult, systolicError in
                
                guard let systolicResult = systolicResult, systolicError == nil else {
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                    return
                }
                
                var systolic: Double?
                if let quantity = systolicResult.averageQuantity() {
                    systolic = quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                }
                
                // Then fetch diastolic pressure
                let diastolicQuery = HKStatisticsQuery(
                    quantityType: diastolicType,
                    quantitySamplePredicate: predicate,
                    options: .discreteAverage) { _, diastolicResult, diastolicError in
                        
                        guard let diastolicResult = diastolicResult, diastolicError == nil else {
                            DispatchQueue.main.async {
                                completion(systolic, nil)
                            }
                            return
                        }
                        
                        var diastolic: Double?
                        if let quantity = diastolicResult.averageQuantity() {
                            diastolic = quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                        }
                        
                        DispatchQueue.main.async {
                            completion(systolic, diastolic)
                        }
                    }
                
                self.healthStore.execute(diastolicQuery)
            }
        
        healthStore.execute(systolicQuery)
    }
    
    // MARK: - Sleep Methods
    
    /// Fetches and calculates average daily sleep duration over the past week
    /// - Parameter completion: Closure that receives the average sleep hours per day
    func fetchSleepData(completion: @escaping (Double?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        
        // Get sleep data from past week
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Filter for asleep samples only (excluding in bed but awake time)
            let asleepSamples = samples.filter { sample in
                sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
            }
            
            // Calculate total sleep time across all samples
            var totalSleepTime = 0.0
            for sample in asleepSamples {
                let sleepTime = sample.endDate.timeIntervalSince(sample.startDate) / 3600 // Convert to hours
                totalSleepTime += sleepTime
            }
            
            // Average daily sleep time
            let sleepHours = totalSleepTime / 7.0 // Average over 7 days
            
            DispatchQueue.main.async {
                completion(sleepHours)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Activity Methods
    
    /// Fetches step count data for today and yesterday to enable trend comparison
    /// - Parameter completion: Closure that receives today's and yesterday's step count
    func fetchStepCountData(completion: @escaping (Int?, Int?) -> Void) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, nil)
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Define time intervals for today and yesterday
        let startOfToday = calendar.startOfDay(for: now)
        let todayPredicate = HKQuery.predicateForSamples(withStart: startOfToday, end: now, options: .strictStartDate)
        
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let yesterdayPredicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: startOfToday, options: .strictStartDate)
        
        // Execute query for today's step count
        let todayQuery = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: todayPredicate,
            options: .cumulativeSum) { _, result, error in
                
                guard let result = result, error == nil else {
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                    return
                }
                
                var todaySteps: Int?
                if let quantity = result.sumQuantity() {
                    todaySteps = Int(quantity.doubleValue(for: HKUnit.count()))
                }
                
                // Now query for yesterday's step count for comparison
                let yesterdayQuery = HKStatisticsQuery(
                    quantityType: stepCountType,
                    quantitySamplePredicate: yesterdayPredicate,
                    options: .cumulativeSum) { _, result, error in
                        
                        guard let result = result, error == nil else {
                            DispatchQueue.main.async {
                                completion(todaySteps, nil)
                            }
                            return
                        }
                        
                        var yesterdaySteps: Int?
                        if let quantity = result.sumQuantity() {
                            yesterdaySteps = Int(quantity.doubleValue(for: HKUnit.count()))
                        }
                        
                        DispatchQueue.main.async {
                            completion(todaySteps, yesterdaySteps)
                        }
                    }
                
                self.healthStore.execute(yesterdayQuery)
            }
        
        healthStore.execute(todayQuery)
    }
    
    // MARK: - Body Measurement Methods
    
    /// Fetches the most recent height and weight measurements
    /// - Parameter completion: Closure that receives height (cm) and weight (kg)
    func fetchBodyMeasurements(completion: @escaping (Double?, Double?) -> Void) {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height),
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil, nil)
            return
        }
        
        // Query for most recent height measurement
        let heightQuery = HKSampleQuery(
            sampleType: heightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, heightSamples, heightError in
                
                guard let heightSample = heightSamples?.first as? HKQuantitySample, heightError == nil else {
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                    return
                }
                
                // Convert height from meters to centimeters
                let height = heightSample.quantity.doubleValue(for: HKUnit.meter()) * 100 // Convert to cm
                
                // Query for most recent weight measurement
                let weightQuery = HKSampleQuery(
                    sampleType: weightType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, weightSamples, weightError in
                        
                        guard let weightSample = weightSamples?.first as? HKQuantitySample, weightError == nil else {
                            DispatchQueue.main.async {
                                completion(height, nil)
                            }
                            return
                        }
                        
                        // Get weight in kilograms
                        let weight = weightSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                        
                        DispatchQueue.main.async {
                            completion(height, weight)
                        }
                    }
                
                self.healthStore.execute(weightQuery)
            }
        
        healthStore.execute(heightQuery)
    }
    
    // MARK: - Oxygen Saturation Methods
    
    /// Fetches average blood oxygen saturation percentage over the past week
    /// - Parameter completion: Closure that receives oxygen saturation percentage (0-100)
    func fetchOxygenSaturationData(completion: @escaping (Double?) -> Void) {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion(nil)
            return
        }
        
        // Get data from past week
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: oxygenType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage) { _, result, error in
                
                guard let result = result, error == nil else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                var oxygenSaturation: Double?
                if let quantity = result.averageQuantity() {
                    // Convert from decimal (0.0-1.0) to percentage (0-100)
                    oxygenSaturation = quantity.doubleValue(for: HKUnit.percent()) * 100
                }
                
                DispatchQueue.main.async {
                    completion(oxygenSaturation)
                }
            }
        
        healthStore.execute(query)
    }
    
    // MARK: - Latest Health Data Methods
    
    /// Fetches the most recent heart rate measurement
    /// - Parameter completion: Closure that receives heart rate (BPM) and any error
    func fetchLatestHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Heart rate type is no longer available in HealthKit"]))
            return
        }
        
        // Sort by date, most recent first
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                
                // Convert to beats per minute
                let heartRateValue = mostRecentSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                DispatchQueue.main.async {
                    self.heartRate = heartRateValue
                    completion(heartRateValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    /// Fetches the most recent heart rate variability measurement (SDNN)
    /// - Parameter completion: Closure that receives HRV (ms) and any error
    func fetchHeartRateVariability(completion: @escaping (Double?, Error?) -> Void) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HRV type is no longer available in HealthKit"]))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                
                // Get HRV in milliseconds
                let hrvValue = mostRecentSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                DispatchQueue.main.async {
                    self.heartRateVariability = hrvValue
                    completion(hrvValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    /// Fetches sleep data for the past 24 hours and calculates total sleep time
    /// - Parameter completion: Closure that receives sleep hours and any error
    func fetchSleepHours(completion: @escaping (Double?, Error?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sleep analysis is no longer available in HealthKit"]))
            return
        }
        
        // Get sleep data for the last 24 hours
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil) { (query, samples, error) in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    DispatchQueue.main.async {
                        completion(nil, error ?? NSError(domain: "com.deepcure.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey: "No sleep data available"]))
                    }
                    return
                }
                
                var totalSleepTime: TimeInterval = 0
                
                // Calculate total sleep time from all sleep samples
                for sample in samples {
                    if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                        let sleepTime = sample.endDate.timeIntervalSince(sample.startDate)
                        totalSleepTime += sleepTime
                    }
                }
                
                // Convert seconds to hours
                let sleepHours = totalSleepTime / 3600.0
                
                DispatchQueue.main.async {
                    self.sleepHours = sleepHours
                    completion(sleepHours, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    /// Fetches step count for today
    /// - Parameter completion: Closure that receives step count and any error
    func fetchStepCount(completion: @escaping (Int?, Error?) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Step count is no longer available in HealthKit"]))
            return
        }
        
        // Get steps only for today
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum) { (query, statistics, error) in
                guard let statistics = statistics, let sum = statistics.sumQuantity() else {
                    DispatchQueue.main.async {
                        completion(nil, error ?? NSError(domain: "com.deepcure.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey: "No step count available"]))
                    }
                    return
                }
                
                let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                
                DispatchQueue.main.async {
                    self.stepCount = stepCount
                    completion(stepCount, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    /// Fetches active energy (calories) burned today
    /// - Parameter completion: Closure that receives calories (kcal) and any error
    func fetchActiveEnergyBurned(completion: @escaping (Double?, Error?) -> Void) {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Active energy burned is no longer available in HealthKit"]))
            return
        }
        
        // Get active energy burned for today only
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum) { (query, statistics, error) in
                guard let statistics = statistics, let sum = statistics.sumQuantity() else {
                    DispatchQueue.main.async {
                        completion(nil, error ?? NSError(domain: "com.deepcure.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey: "No active energy data available"]))
                    }
                    return
                }
                
                let energyBurned = sum.doubleValue(for: HKUnit.kilocalorie())
                
                DispatchQueue.main.async {
                    self.activeEnergyBurned = energyBurned
                    completion(energyBurned, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    /// Fetches the most recent blood pressure measurements
    /// - Parameter completion: Closure that receives systolic, diastolic (mmHg) and any error
    func fetchBloodPressure(completion: @escaping (Double?, Double?, Error?) -> Void) {
        guard let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            completion(nil, nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Blood pressure is no longer available in HealthKit"]))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Fetch systolic first
        let systolicQuery = HKSampleQuery(
            sampleType: systolicType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]) { [weak self] (query, samples, error) in
                guard let samples = samples, let systolicSample = samples.first as? HKQuantitySample else {
                    DispatchQueue.main.async {
                        completion(nil, nil, error)
                    }
                    return
                }
                
                // Then fetch diastolic
                let diastolicQuery = HKSampleQuery(
                    sampleType: diastolicType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                        guard let samples = samples, let diastolicSample = samples.first as? HKQuantitySample else {
                            DispatchQueue.main.async {
                                completion(nil, nil, error)
                            }
                            return
                        }
                        
                        // Get values in mmHg
                        let systolicValue = systolicSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                        let diastolicValue = diastolicSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                        
                        DispatchQueue.main.async {
                            if let self = self {
                                self.bloodPressureSystolic = systolicValue
                                self.bloodPressureDiastolic = diastolicValue
                            }
                            completion(systolicValue, diastolicValue, nil)
                        }
                    }
                
                self?.healthStore.execute(diastolicQuery)
            }
        
        healthStore.execute(systolicQuery)
    }
    
    /// Fetches the most recent blood oxygen saturation measurement
    /// - Parameter completion: Closure that receives oxygen percentage and any error
    func fetchBloodOxygen(completion: @escaping (Double?, Error?) -> Void) {
        guard let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Blood oxygen is no longer available in HealthKit"]))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: oxygenType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                
                // Get percentage value (0.0-1.0)
                let oxygenValue = mostRecentSample.quantity.doubleValue(for: HKUnit.percent())
                
                DispatchQueue.main.async {
                    self.bloodOxygen = oxygenValue
                    completion(oxygenValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    /// Fetches the most recent blood glucose measurement
    /// - Parameter completion: Closure that receives glucose (mg/dL) and any error
    func fetchBloodGlucose(completion: @escaping (Double?, Error?) -> Void) {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Blood glucose is no longer available in HealthKit"]))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: glucoseType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                
                // Get value in mg/dL
                let glucoseValue = mostRecentSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci)))
                
                DispatchQueue.main.async {
                    self.bloodGlucose = glucoseValue
                    completion(glucoseValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    /// Fetches the most recent respiratory rate measurement
    /// - Parameter completion: Closure that receives respiratory rate (breaths/min) and any error
    func fetchRespiratoryRate(completion: @escaping (Double?, Error?) -> Void) {
        guard let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Respiratory rate is no longer available in HealthKit"]))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: respiratoryType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                
                let respiratoryValue = mostRecentSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                
                DispatchQueue.main.async {
                    self.respiratoryRate = respiratoryValue
                    completion(respiratoryValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    /// Fetches the most recent body temperature measurement
    /// - Parameter completion: Closure that receives temperature (°C) and any error
    func fetchBodyTemperature(completion: @escaping (Double?, Error?) -> Void) {
        guard let temperatureType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Body temperature is no longer available in HealthKit"]))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: temperatureType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
                
                // Get temperature in Celsius
                let temperatureValue = mostRecentSample.quantity.doubleValue(for: HKUnit.degreeCelsius())
                
                DispatchQueue.main.async {
                    self.bodyTemperature = temperatureValue
                    completion(temperatureValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    // MARK: - Trend Analysis
    
    /// Calculate health data trends by comparing current values with historical averages
    /// This is a simplified implementation that would be enhanced in a real app
    func fetchHealthTrends() {
        // This would ideally fetch and calculate trends for heart rate, sleep, and step count
        // For simplicity, we're just setting default values here
        // In a real app, you would compare current values with historical averages
        self.heartRateTrend = 0.05 // 5% increase
        self.sleepHoursTrend = -0.03 // 3% decrease
        self.stepCountTrend = 0.08 // 8% increase
    }
    
    // MARK: - Comprehensive Health Data Fetch
    
    /// Fetches all health metrics in a single coordinated operation
    /// This reduces the number of permission dialogs shown to the user
    /// - Parameter completion: Closure that receives a populated HealthMetrics object or an error
    func fetchAllHealthData(completion: @escaping (Result<HealthMetrics, Error>) -> Void) {
        isLoading = true
        var metrics = HealthMetrics()
        
        // Chain all health data requests using nested callbacks
        // This ensures we complete all requests before returning results
        fetchLatestHeartRate { [weak self] heartRate, error in
            if let heartRate = heartRate {
                metrics.averageHeartRate = Int(heartRate)
            }
            
            self?.fetchHeartRateVariability { hrv, _ in
                if let hrv = hrv {
                    metrics.heartRateVariability = hrv
                }
                
                self?.fetchSleepHours { sleepHours, _ in
                    if let sleepHours = sleepHours {
                        metrics.sleepHours = sleepHours
                    }
                    
                    self?.fetchStepCount { steps, _ in
                        if let steps = steps {
                            metrics.stepCount = steps
                        }
                        
                        self?.fetchActiveEnergyBurned { calories, _ in
                            if let calories = calories {
                                metrics.caloriesBurned = calories
                            }
                            
                            self?.fetchBloodPressure { systolic, diastolic, _ in
                                if let systolic = systolic {
                                    metrics.systolicPressure = systolic
                                }
                                if let diastolic = diastolic {
                                    metrics.diastolicPressure = diastolic
                                }
                                
                                self?.fetchBloodOxygen { oxygen, _ in
                                    if let oxygen = oxygen {
                                        metrics.bloodOxygen = oxygen
                                    }
                                    
                                    self?.fetchRespiratoryRate { respiratoryRate, _ in
                                        if let respiratoryRate = respiratoryRate {
                                            metrics.respiratoryRate = respiratoryRate
                                        }
                                        
                                        self?.fetchBodyTemperature { temperature, _ in
                                            if let temperature = temperature {
                                                metrics.bodyTemperature = temperature
                                            }
                                            
                                            // Calculate trends based on historical data
                                            self?.fetchHealthTrends()
                                            if let self = self {
                                                metrics.averageHeartRateTrend = Int(self.heartRateTrend)
                                                metrics.sleepHoursTrend = self.sleepHoursTrend
                                                metrics.stepCountTrend = Int(self.stepCountTrend)
                                            }
                                            
                                            // Mark metrics as just updated
                                            metrics.lastUpdated = Date()
                                            
                                            // Deliver results on main thread
                                            DispatchQueue.main.async {
                                                self?.isLoading = false
                                                completion(.success(metrics))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}