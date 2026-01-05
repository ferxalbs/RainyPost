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
            // Background with subtle blur effect
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: "cloud.rain.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("RainyPost")
                        .font(.system(size: 32, weight: .light, design: .default))
                        .foregroundColor(.primary)
                    
                    Text("Native macOS API Client")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingWorkspacePicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Workspace")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showingWorkspacePicker = true
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("Open Existing Workspace")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 280)
                
                Spacer()
                
                // Footer
                Text("Offline-first • File-based • Secure")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.secondary)
            }
            .padding(40)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

// Visual Effect View for macOS blur
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    WelcomeView(showingWorkspacePicker: .constant(false))
}