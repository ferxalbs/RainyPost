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
            HStack(spacing: 7) {
                Circle()
                    .fill(appState.activeEnvironment != nil ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Text(appState.activeEnvironment?.name ?? "No Environment")
                    .font(.system(size: 13, weight: .medium))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
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
