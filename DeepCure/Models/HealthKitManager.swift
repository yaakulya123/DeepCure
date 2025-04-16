import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    // Add shared singleton instance
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties to track authorization status
    @Published var isAuthorized = false
    @Published var authorizationError: Error?
    @Published var isLoading = false
    
    // Published properties for health metrics
    @Published var heartRate: Double = 0
    @Published var heartRateTrend: Double = 0
    @Published var heartRateVariability: Double = 0
    @Published var sleepHours: Double = 0
    @Published var sleepHoursTrend: Double = 0
    @Published var stepCount: Int = 0
    @Published var stepCountTrend: Double = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var bloodPressureSystolic: Double = 0
    @Published var bloodPressureDiastolic: Double = 0
    @Published var bloodOxygen: Double = 0
    @Published var bloodGlucose: Double = 0
    @Published var respiratoryRate: Double = 0
    @Published var bodyTemperature: Double = 0
    
    // Types of data we want to read from HealthKit
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
    
    // Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    private init() {
        // Private initializer to enforce singleton usage
    }
    
    // Request authorization to access HealthKit data
    func requestAuthorization(completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard isHealthKitAvailable else {
            let error = NSError(domain: "com.deepcure.healthkit", code: 0, 
                               userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"])
            authorizationError = error
            completion(false, error)
            return
        }
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                self?.authorizationError = error
                completion(success, error)
            }
        }
    }
    
    // Fetch heart rate data
    func fetchHeartRateData(completion: @escaping (Double?, Double?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(nil, nil)
            return
        }
        
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
                
                if let quantity = result.averageQuantity() {
                    avgHeartRate = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
                
                if let quantity = result.maximumQuantity() {
                    maxHeartRate = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
                
                DispatchQueue.main.async {
                    completion(avgHeartRate, maxHeartRate)
                }
            }
        
        healthStore.execute(query)
    }
    
    // Fetch blood pressure data
    func fetchBloodPressureData(completion: @escaping (Double?, Double?) -> Void) {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            completion(nil, nil)
            return
        }
        
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        // Fetch systolic pressure
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
                
                // Fetch diastolic pressure
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
    
    // Fetch sleep data
    func fetchSleepData(completion: @escaping (Double?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        
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
            
            // Filter for asleep samples only
            let asleepSamples = samples.filter { sample in
                sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
            }
            
            // Calculate total sleep time
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
    
    // Fetch step count data
    func fetchStepCountData(completion: @escaping (Int?, Int?) -> Void) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, nil)
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Step count for today
        let startOfToday = calendar.startOfDay(for: now)
        let todayPredicate = HKQuery.predicateForSamples(withStart: startOfToday, end: now, options: .strictStartDate)
        
        // Step count for yesterday
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let yesterdayPredicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: startOfToday, options: .strictStartDate)
        
        // Query for today's step count
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
                
                // Query for yesterday's step count
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
    
    // Fetch body measurements (height and weight)
    func fetchBodyMeasurements(completion: @escaping (Double?, Double?) -> Void) {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height),
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil, nil)
            return
        }
        
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
                
                let height = heightSample.quantity.doubleValue(for: HKUnit.meter()) * 100 // Convert to cm
                
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
                        
                        let weight = weightSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                        
                        DispatchQueue.main.async {
                            completion(height, weight)
                        }
                    }
                
                self.healthStore.execute(weightQuery)
            }
        
        healthStore.execute(heightQuery)
    }
    
    // Fetch oxygen saturation data
    func fetchOxygenSaturationData(completion: @escaping (Double?) -> Void) {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion(nil)
            return
        }
        
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
                    oxygenSaturation = quantity.doubleValue(for: HKUnit.percent()) * 100
                }
                
                DispatchQueue.main.async {
                    completion(oxygenSaturation)
                }
            }
        
        healthStore.execute(query)
    }
    
    // Fetch the latest heart rate
    func fetchLatestHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Heart rate type is no longer available in HealthKit"]))
            return
        }
        
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
                
                let heartRateValue = mostRecentSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                DispatchQueue.main.async {
                    self.heartRate = heartRateValue
                    completion(heartRateValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    // Fetch heart rate variability
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
                
                let hrvValue = mostRecentSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                DispatchQueue.main.async {
                    self.heartRateVariability = hrvValue
                    completion(hrvValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    // Fetch sleep data
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
                
                // Calculate total sleep time
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
    
    // Fetch step count for today
    func fetchStepCount(completion: @escaping (Int?, Error?) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Step count is no longer available in HealthKit"]))
            return
        }
        
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
    
    // Fetch active energy burned for today
    func fetchActiveEnergyBurned(completion: @escaping (Double?, Error?) -> Void) {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil, NSError(domain: "com.deepcure.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Active energy burned is no longer available in HealthKit"]))
            return
        }
        
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
    
    // Fetch blood pressure data
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
                        
                        // Get values
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
    
    // Fetch blood oxygen saturation
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
                
                // Percentage value
                let oxygenValue = mostRecentSample.quantity.doubleValue(for: HKUnit.percent())
                
                DispatchQueue.main.async {
                    self.bloodOxygen = oxygenValue
                    completion(oxygenValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    // Fetch blood glucose level
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
                
                // mg/dL value
                let glucoseValue = mostRecentSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci)))
                
                DispatchQueue.main.async {
                    self.bloodGlucose = glucoseValue
                    completion(glucoseValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    // Fetch respiratory rate
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
    
    // Fetch body temperature
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
                
                // Celsius value
                let temperatureValue = mostRecentSample.quantity.doubleValue(for: HKUnit.degreeCelsius())
                
                DispatchQueue.main.async {
                    self.bodyTemperature = temperatureValue
                    completion(temperatureValue, nil)
                }
            }
        
        healthStore.execute(query)
    }
    
    // Fetch trend data (average compared to previous days)
    func fetchHealthTrends() {
        // This would ideally fetch and calculate trends for heart rate, sleep, and step count
        // For simplicity, we're just setting default values here
        // In a real app, you would compare current values with historical averages
        self.heartRateTrend = 0.05 // 5% increase
        self.sleepHoursTrend = -0.03 // 3% decrease
        self.stepCountTrend = 0.08 // 8% increase
    }
    
    // Fetch all health data at once
    func fetchAllHealthData() {
        isLoading = true
        
        fetchLatestHeartRate { [weak self] _, _ in
            self?.fetchHeartRateVariability { _, _ in
                self?.fetchSleepHours { _, _ in
                    self?.fetchStepCount { _, _ in
                        self?.fetchActiveEnergyBurned { _, _ in
                            self?.fetchBloodPressure { _, _, _ in
                                self?.fetchBloodOxygen { _, _ in
                                    self?.fetchBloodGlucose { _, _ in
                                        self?.fetchRespiratoryRate { _, _ in
                                            self?.fetchBodyTemperature { _, _ in
                                                self?.fetchHealthTrends()
                                                DispatchQueue.main.async {
                                                    self?.isLoading = false
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
}