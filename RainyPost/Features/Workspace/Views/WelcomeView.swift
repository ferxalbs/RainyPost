//
//  WelcomeView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var showingWorkspacePicker: Bool
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "cloud.rain.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("RainyPost")
                        .font(.system(size: 24, weight: .light))
                    
                    Text("Native macOS API Client")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Buttons
                VStack(spacing: 8) {
                    Button(action: { showingWorkspacePicker = true }) {
                        Label("Create New Workspace", systemImage: "plus.circle.fill")
                            .frame(width: 180)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: { showingWorkspacePicker = true }) {
                        Label("Open Existing", systemImage: "folder")
                            .frame(width: 180)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Spacer()
                
                Text("Offline-first • File-based • Secure")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
            }
            .padding(32)
        }
        .frame(minWidth: 800, minHeight: 400)
    }
}

#Preview {
    WelcomeView(showingWorkspacePicker: .constant(false))
        .frame(width: 800, height: 500)
}
