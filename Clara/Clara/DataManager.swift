//
//  DataManager.swift
//  Clara
//
//  Created by Tatiana Ampilogova on 12/4/24.
//

import Foundation

import SwiftUI
import HealthKit
import EventKit

class DataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let eventStore = EKEventStore()

    @Published var isHealthAuthorized = false
    @Published var isCalendarAuthorized = false

    func requestHealthAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let menstrualFlowType = HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
        healthStore.requestAuthorization(toShare: nil, read: [menstrualFlowType]) { success, error in
            DispatchQueue.main.async {
                self.isHealthAuthorized = success
                if success {
                    print("HealthKit access granted")
                } else {
                    print("HealthKit access denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    func requestCalendarAuthorization() {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                self.isCalendarAuthorized = granted
                if granted {
                    print("Calendar access granted")
                } else {
                    print("Calendar access denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    func fetchMenstrualDataAndSync() {
        let menstrualFlowType = HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
        let query = HKSampleQuery(sampleType: menstrualFlowType, predicate: nil, limit: 0, sortDescriptors: nil) { query, results, error in
            guard let samples = results as? [HKCategorySample] else { return }
            
            // Fetch historical cycles
            let pastCycles = samples.map { sample in
                MenstrualCycle(startDate: sample.startDate, endDate: sample.endDate)
            }
            
            // Predict future periods
            let predictions = self.predictFuturePeriods(pastCycles: pastCycles, numberOfPredictions: 3)
            print(predictions)
            // Sync both historical and predicted events to the calendar
            DispatchQueue.main.async {
                for cycle in pastCycles + predictions {
                    self.addEventToCalendar(
                        title: "🌸",
                        startDate: cycle.startDate,
                        endDate: cycle.endDate,
                        notes: "Track your period."
                    )
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func addEventToCalendar(title: String, startDate: Date, endDate: Date, notes: String) {
        guard isCalendarAuthorized else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.isAllDay = true
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Error saving event to calendar: \(error.localizedDescription)")
        }
    }

    // Predict future periods
    func predictFuturePeriods(pastCycles: [MenstrualCycle], numberOfPredictions: Int) -> [MenstrualCycle] {
        guard !pastCycles.isEmpty else { return [] }
        
        let calendar = Calendar.current

        // Calculate average cycle length
        let cycleLengths = pastCycles.enumerated().compactMap { (index, cycle) -> Int? in
            guard index > 0 else { return nil }
            return calendar.dateComponents([.day], from: pastCycles[index - 1].startDate, to: cycle.startDate).day
        }
        let averageCycleLength = cycleLengths.reduce(0, +) / max(cycleLengths.count, 1)

        // Calculate average period duration
        let periodDurations = pastCycles.map { cycle in
            calendar.dateComponents([.day], from: cycle.startDate, to: cycle.endDate).day ?? 0
        }
        let averagePeriodDuration = periodDurations.reduce(0, +) / max(periodDurations.count, 1)

        var predictions: [MenstrualCycle] = []
        var lastCycle = pastCycles.last!

        for _ in 0..<numberOfPredictions {
            let nextStartDate = calendar.date(byAdding: .day, value: averageCycleLength, to: lastCycle.startDate)!
            let nextEndDate = calendar.date(byAdding: .day, value: averagePeriodDuration, to: nextStartDate)!
            let nextCycle = MenstrualCycle(startDate: nextStartDate, endDate: nextEndDate)
            predictions.append(nextCycle)
            lastCycle = nextCycle
        }
        
        return predictions
    }
}

// Menstrual Cycle Data Model
struct MenstrualCycle {
    let startDate: Date
    let endDate: Date
}
