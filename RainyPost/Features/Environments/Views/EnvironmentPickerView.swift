//
//  EnvironmentPickerView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct EnvironmentPickerView: View {
    @EnvironmentObject private var appState: AppState
    
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
                // TODO: Open environment manager
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(appState.activeEnvironment != nil ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                
                Text(appState.activeEnvironment?.name ?? "No Environment")
                    .font(.system(size: 11, weight: .medium))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
    }
}

#Preview {
    EnvironmentPickerView()
        .environmentObject(AppState())
}