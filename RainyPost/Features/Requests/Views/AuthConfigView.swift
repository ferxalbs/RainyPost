//
//  AuthConfigView.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI

struct AuthConfigView: View {
    @ObservedObject var viewModel: RequestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Auth Type Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Authentication Type")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.authType) {
                    ForEach(AuthType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 400)
            }
            
            // Auth Config based on type
            switch viewModel.authType {
            case .none:
                noAuthView
            case .bearer:
                bearerAuthView
            case .basic:
                basicAuthView
            case .apiKey:
                apiKeyAuthView
            }
            
            Spacer()
        }
    }
    
    private var noAuthView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.open")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("No authentication")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private var bearerAuthView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Token")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            SecureInputField(
                placeholder: "Enter bearer token",
                text: $viewModel.authToken
            )
            
            Text("The token will be sent as: Authorization: Bearer <token>")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, 4)
        }
    }
    
    private var basicAuthView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextField("Username", text: $viewModel.authUsername)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
                    .frame(maxWidth: 300)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                SecureInputField(
                    placeholder: "Password",
                    text: $viewModel.authPassword
                )
                .frame(maxWidth: 300)
            }
        }
    }
    
    private var apiKeyAuthView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Key Name")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("X-API-Key", text: $viewModel.apiKeyName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                        )
                        .frame(width: 150)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add to")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $viewModel.apiKeyLocation) {
                        Text("Header").tag(APIKeyLocation.header)
                        Text("Query").tag(APIKeyLocation.query)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Value")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                SecureInputField(
                    placeholder: "API Key Value",
                    text: $viewModel.apiKeyValue
                )
                .frame(maxWidth: 300)
            }
        }
    }
}

struct SecureInputField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 8) {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 12, design: .monospaced))
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    AuthConfigView(viewModel: RequestViewModel(request: Request(name: "Test", method: .GET, url: "")))
        .padding()
        .frame(width: 500, height: 300)
}
