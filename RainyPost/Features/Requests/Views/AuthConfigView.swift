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
            // Type Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Type")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.authType) {
                    ForEach(AuthType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(maxWidth: 350)
            }
            
            // Auth Fields
            switch viewModel.authType {
            case .none:
                Text("No authentication")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                
            case .bearer:
                VStack(alignment: .leading, spacing: 4) {
                    Text("Token")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    SecureField("Bearer token", text: $viewModel.authToken)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: 350)
                }
                
            case .basic:
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextField("Username", text: $viewModel.authUsername)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                            .frame(width: 160)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        SecureField("Password", text: $viewModel.authPassword)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                            .frame(width: 160)
                    }
                }
                
            case .apiKey:
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextField("X-API-Key", text: $viewModel.apiKeyName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                            .frame(width: 120)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Value")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        SecureField("API Key", text: $viewModel.apiKeyValue)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 200)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add to")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        Picker("", selection: $viewModel.apiKeyLocation) {
                            Text("Header").tag(APIKeyLocation.header)
                            Text("Query").tag(APIKeyLocation.query)
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AuthConfigView(viewModel: RequestViewModel(request: Request(name: "Test", method: .GET, url: "")))
        .padding()
        .frame(width: 500, height: 300)
}
