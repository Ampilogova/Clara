//
//  MainView.swift
//  Clara
//
//  Created by Tatiana Ampilogova on 12/4/24.
//

import SwiftUI

struct MainView: View {
    @StateObject private var dataManager = DataManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // HealthKit Permission
                Button(action: dataManager.requestHealthAuthorization) {
                    HStack {
                        Image(systemName: dataManager.isHealthAuthorized ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(dataManager.isHealthAuthorized ? .green : .gray)
                        Text("Authorize HealthKit")
                    }
                }
                .disabled(dataManager.isHealthAuthorized)

                // Calendar Permission
                Button(action: dataManager.requestCalendarAuthorization) {
                    HStack {
                        Image(systemName: dataManager.isCalendarAuthorized ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(dataManager.isCalendarAuthorized ? .green : .gray)
                        Text("Authorize Calendar")
                    }
                }
                .disabled(dataManager.isCalendarAuthorized)

                // Sync Menstrual Data
                Button(action: dataManager.fetchMenstrualDataAndSync) {
                    Text("Sync Menstrual Data to Calendar")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!dataManager.isHealthAuthorized || !dataManager.isCalendarAuthorized)
            }
            .padding()
            .navigationTitle("Cycle Sync")
        }
    }
}
