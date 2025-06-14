import Foundation
import HealthKit
import Combine

protocol HealthServiceProtocol {
    var healthDataPublisher: AnyPublisher<HealthData, Never> { get }
    var authorizationStatusPublisher: AnyPublisher<HealthAuthorizationStatus, Never> { get }
    
    func requestAuthorization() async throws
    func checkAuthorizationStatus() async -> HealthAuthorizationStatus
    func startMonitoring() async
    func stopMonitoring()
}

class HealthService: HealthServiceProtocol {
    private let healthStore = HKHealthStore()
    private let healthDataSubject = CurrentValueSubject<HealthData, Never>(HealthData())
    private let authStatusSubject = CurrentValueSubject<HealthAuthorizationStatus, Never>(.notDetermined)
    
    private var queries: [HKQuery] = []
    private var workoutSession: HKWorkoutSession?
    
    var healthDataPublisher: AnyPublisher<HealthData, Never> {
        healthDataSubject.eraseToAnyPublisher()
    }
    
    var authorizationStatusPublisher: AnyPublisher<HealthAuthorizationStatus, Never> {
        authStatusSubject.eraseToAnyPublisher()
    }
    
    init() {
        checkInitialAuthorizationStatus()
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.healthDataNotAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead)
        
        await updateAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() async -> HealthAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .restricted
        }
        
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let authStatus = healthStore.authorizationStatus(for: stepCountType)
        
        let status: HealthAuthorizationStatus
        switch authStatus {
        case .notDetermined:
            status = .notDetermined
        case .sharingDenied:
            status = .denied
        case .sharingAuthorized:
            status = .authorized
        @unknown default:
            status = .notDetermined
        }
        
        await MainActor.run {
            authStatusSubject.send(status)
        }
        
        return status
    }
    
    func startMonitoring() async {
        let authStatus = await checkAuthorizationStatus()
        guard authStatus == .authorized else { return }
        
        await startStepCountMonitoring()
        await startHeartRateMonitoring()
        await startExerciseTimeMonitoring()
        await startStandTimeMonitoring()
        await startMindfulnessMonitoring()
    }
    
    func stopMonitoring() {
        for query in queries {
            healthStore.stop(query)
        }
        queries.removeAll()
        workoutSession?.end()
    }
    
    private func checkInitialAuthorizationStatus() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    private func updateAuthorizationStatus() async {
        let status = await checkAuthorizationStatus()
        await MainActor.run {
            authStatusSubject.send(status)
        }
    }
    
    private func startStepCountMonitoring() async {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching step count: \(error)")
                return
            }
            
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            
            Task { @MainActor in
                var currentData = self.healthDataSubject.value
                currentData.steps = Int(steps)
                self.healthDataSubject.send(currentData)
            }
        }
        
        healthStore.execute(query)
        queries.append(query)
        
        let anchoredQuery = HKAnchoredObjectQuery(
            type: stepType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard let self = self else { return }
            self.handleStepCountUpdate(samples: samples, error: error)
        }
        
        anchoredQuery.updateHandler = { [weak self] _, samples, _, _, error in
            guard let self = self else { return }
            self.handleStepCountUpdate(samples: samples, error: error)
        }
        
        healthStore.execute(anchoredQuery)
        queries.append(anchoredQuery)
    }
    
    private func handleStepCountUpdate(samples: [HKSample]?, error: Error?) {
        if let error = error {
            print("Error in step count update: \(error)")
            return
        }
        
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        let totalSteps = samples.reduce(0) { result, sample in
            result + sample.quantity.doubleValue(for: HKUnit.count())
        }
        
        Task { @MainActor in
            var currentData = self.healthDataSubject.value
            currentData.steps = Int(totalSteps)
            self.healthDataSubject.send(currentData)
        }
    }
    
    private func startHeartRateMonitoring() async {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: 1
        ) { [weak self] _, samples, _, _, error in
            self?.handleHeartRateUpdate(samples: samples, error: error)
        }
        
        query.updateHandler = { [weak self] _, samples, _, _, error in
            self?.handleHeartRateUpdate(samples: samples, error: error)
        }
        
        healthStore.execute(query)
        queries.append(query)
    }
    
    private func handleHeartRateUpdate(samples: [HKSample]?, error: Error?) {
        if let error = error {
            print("Error in heart rate update: \(error)")
            return
        }
        
        guard let samples = samples as? [HKQuantitySample],
              let latestSample = samples.last else { return }
        
        let heartRate = latestSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        
        Task { @MainActor in
            var currentData = self.healthDataSubject.value
            currentData.heartRate = heartRate
            self.healthDataSubject.send(currentData)
        }
    }
    
    private func startExerciseTimeMonitoring() async {
        guard let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching exercise time: \(error)")
                return
            }
            
            let minutes = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
            
            Task { @MainActor in
                var currentData = self.healthDataSubject.value
                currentData.exerciseMinutes = Int(minutes)
                self.healthDataSubject.send(currentData)
            }
        }
        
        healthStore.execute(query)
        queries.append(query)
    }
    
    private func startStandTimeMonitoring() async {
        guard let standType = HKObjectType.quantityType(forIdentifier: .appleStandTime) else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: standType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching stand time: \(error)")
                return
            }
            
            let hours = result?.sumQuantity()?.doubleValue(for: HKUnit.hour()) ?? 0
            
            Task { @MainActor in
                var currentData = self.healthDataSubject.value
                currentData.standingHours = Int(hours)
                self.healthDataSubject.send(currentData)
            }
        }
        
        healthStore.execute(query)
        queries.append(query)
    }
    
    private func startMindfulnessMonitoring() async {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: mindfulType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching mindfulness data: \(error)")
                return
            }
            
            let totalMinutes = samples?.reduce(0) { result, sample in
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                return result + (duration / 60.0)
            } ?? 0
            
            Task { @MainActor in
                var currentData = self.healthDataSubject.value
                currentData.mindfulMinutes = Int(totalMinutes)
                self.healthDataSubject.send(currentData)
            }
        }
        
        healthStore.execute(query)
        queries.append(query)
    }
}

enum HealthServiceError: Error, LocalizedError {
    case healthDataNotAvailable
    case authorizationDenied
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device"
        case .authorizationDenied:
            return "Health data access was denied"
        case .queryFailed(let message):
            return "Health query failed: \(message)"
        }
    }
}