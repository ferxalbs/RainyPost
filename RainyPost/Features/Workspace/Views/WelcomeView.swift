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
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 48) {
                Spacer()
                
                // App Icon and Title
                VStack(spacing: 24) {
                    Image(systemName: "cloud.rain.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 30, x: 0, y: 15)
                    
                    VStack(spacing: 8) {
                        Text("RainyPost")
                            .font(.system(size: 42, weight: .thin, design: .default))
                            .foregroundColor(.primary)
                        
                        Text("Native macOS API Client")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 14) {
                    Button(action: {
                        showingWorkspacePicker = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Create New Workspace")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Button(action: {
                        showingWorkspacePicker = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 16))
                            Text("Open Existing Workspace")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 320)
                
                Spacer()
                
                // Footer
                Text("Offline-first • File-based • Secure")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .padding(60)
        }
        .frame(minWidth: 800, minHeight: 400)
    }
}

// Visual Effect View for macOS blur
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    var isEmphasized: Bool = false
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = isEmphasized
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = isEmphasized
    }
}

#Preview {
    WelcomeView(showingWorkspacePicker: .constant(false))
        .frame(width: 1200, height: 800)
}
