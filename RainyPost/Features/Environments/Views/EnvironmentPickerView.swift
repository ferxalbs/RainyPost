//
//  EnvironmentPickerView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct EnvironmentPickerView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingManager = false
    
    var body: some View {
        Menu {
            ForEach(appState.environments) { environment in
                Button(action: {
                    Task {
                        await appState.setActiveEnvironment(environment)
                    }
                }) {
                    HStack {
                        Text(environment.name)
                        if environment.isActive {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            if !appState.environments.isEmpty {
                Divider()
            }
            
            Button("Manage Environments...") {
                showingManager = true
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(appState.activeEnvironment != nil ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                
                Text(appState.activeEnvironment?.name ?? "No Environment")
                    .font(.system(size: 11))
            }
        }
        .menuStyle(.borderlessButton)
        .sheet(isPresented: $showingManager) {
            EnvironmentManagerView()
        }
    }
}

#Preview {
    EnvironmentPickerView()
        .environmentObject(AppState())
}
