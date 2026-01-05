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
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.system(size: 12))
                
                Text(appState.activeEnvironment?.name ?? "No Environment")
                    .font(.system(size: 12, weight: .medium))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
    }
}

#Preview {
    EnvironmentPickerView()
        .environmentObject(AppState())
}