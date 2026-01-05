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
        VStack(alignment: .leading, spacing: 24) {
            // Auth Type Picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Authentication Type")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.authType) {
                    ForEach(AuthType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 480)
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
        VStack(spacing: 12) {
            Image(systemName: "lock.open")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.3))
            
            Text("No authentication")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
    
    private var bearerAuthView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Token")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            
            SecureInputField(
                placeholder: "Enter bearer token",
                text: $viewModel.authToken
            )
            .frame(maxWidth: 400)
            
            Text("The token will be sent as: Authorization: Bearer <token>")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 6)
        }
    }
    
    private var basicAuthView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Username")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextField("Username", text: $viewModel.authUsername)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
                    .frame(maxWidth: 360)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Password")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                SecureInputField(
                    placeholder: "Password",
                    text: $viewModel.authPassword
                )
                .frame(maxWidth: 360)
            }
        }
    }
    
    private var apiKeyAuthView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Key Name")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("X-API-Key", text: $viewModel.apiKeyName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                        )
                        .frame(width: 180)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Add to")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $viewModel.apiKeyLocation) {
                        Text("Header").tag(APIKeyLocation.header)
                        Text("Query").tag(APIKeyLocation.query)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Value")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                SecureInputField(
                    placeholder: "API Key Value",
                    text: $viewModel.apiKeyValue
                )
                .frame(maxWidth: 360)
            }
        }
    }
}

struct SecureInputField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 10) {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 14, design: .monospaced))
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    AuthConfigView(viewModel: RequestViewModel(request: Request(name: "Test", method: .GET, url: "")))
        .padding()
        .frame(width: 600, height: 400)
}
