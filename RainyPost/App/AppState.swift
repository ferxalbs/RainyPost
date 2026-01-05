//
//  AppState.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var currentWorkspace: Workspace?
    @Published var workspaceURL: URL?
    @Published var collections: [Collection] = []
    @Published var requests: [Request] = []
    @Published var environments: [APIEnvironment] = []
    @Published var activeEnvironment: APIEnvironment?
    @Published var selectedRequest: Request?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let workspaceManager = WorkspaceManager()
    
    func createWorkspace(name: String, at url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let workspace = Workspace(name: name)
            try await workspaceManager.createWorkspace(workspace, at: url)
            
            // The actual workspace folder is url/name
            let workspaceFolder = url.appendingPathComponent(name)
            
            self.currentWorkspace = workspace
            self.workspaceURL = workspaceFolder
            self.collections = []
            self.requests = []
            self.environments = []
            self.activeEnvironment = nil
            self.selectedRequest = nil
            
        } catch {
            self.errorMessage = "Failed to create workspace: \(error.localizedDescription)"
            print("Workspace creation error: \(error)")
        }
    }
    
    func openWorkspace(at url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let workspace = try await workspaceManager.loadWorkspace(from: url)
            let collections = try await workspaceManager.loadCollections(from: url)
            let requests = try await workspaceManager.loadRequests(from: url)
            let environments = try await workspaceManager.loadEnvironments(from: url)
            
            self.currentWorkspace = workspace
            self.workspaceURL = url
            self.collections = collections
            self.requests = requests
            self.environments = environments
            self.activeEnvironment = environments.first { $0.isActive }
            self.selectedRequest = nil
            
        } catch {
            self.errorMessage = "Failed to open workspace: \(error.localizedDescription)"
        }
    }
    
    func closeWorkspace() {
        currentWorkspace = nil
        workspaceURL = nil
        collections = []
        requests = []
        environments = []
        activeEnvironment = nil
        selectedRequest = nil
    }
    
    func createRequest(name: String, in collectionId: UUID? = nil) async {
        guard let workspaceURL = workspaceURL else { return }
        
        let request = Request(name: name, collectionId: collectionId)
        
        do {
            try await workspaceManager.saveRequest(request, to: workspaceURL)
            requests.append(request)
        } catch {
            errorMessage = "Failed to create request: \(error.localizedDescription)"
        }
    }
    
    func createCollection(name: String, parentId: UUID? = nil) async {
        guard let workspaceURL = workspaceURL else { return }
        
        let collection = Collection(name: name, parentId: parentId)
        
        do {
            try await workspaceManager.saveCollection(collection, to: workspaceURL)
            collections.append(collection)
        } catch {
            errorMessage = "Failed to create collection: \(error.localizedDescription)"
        }
    }
    
    func createEnvironment(name: String) async {
        guard let workspaceURL = workspaceURL else { return }
        
        let environment = APIEnvironment(name: name)
        
        do {
            try await workspaceManager.saveEnvironment(environment, to: workspaceURL)
            environments.append(environment)
        } catch {
            errorMessage = "Failed to create environment: \(error.localizedDescription)"
        }
    }
    
    func setActiveEnvironment(_ environment: APIEnvironment) async {
        guard let workspaceURL = workspaceURL else { return }
        
        // Deactivate current active environment
        if let currentActive = activeEnvironment {
            var updated = currentActive
            updated.isActive = false
            try? await workspaceManager.saveEnvironment(updated, to: workspaceURL)
            
            if let index = environments.firstIndex(where: { $0.id == currentActive.id }) {
                environments[index] = updated
            }
        }
        
        // Activate new environment
        var updated = environment
        updated.isActive = true
        
        do {
            try await workspaceManager.saveEnvironment(updated, to: workspaceURL)
            
            if let index = environments.firstIndex(where: { $0.id == environment.id }) {
                environments[index] = updated
            }
            
            activeEnvironment = updated
        } catch {
            errorMessage = "Failed to set active environment: \(error.localizedDescription)"
        }
    }
}