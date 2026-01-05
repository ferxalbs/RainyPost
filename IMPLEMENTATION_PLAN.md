# RainyPost - macOS Native API Client
## Implementation Plan & Architecture Document

> **Vision**: A production-grade, offline-first macOS API client for developers. Fast, stable, secure, and with premium UX.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Development Phases](#development-phases)
3. [Technical Architecture](#technical-architecture)
4. [Data Models](#data-models)
5. [Persistence Strategy](#persistence-strategy)
6. [Project Structure](#project-structure)
7. [QA & Testing Plan](#qa--testing-plan)
8. [UX Design](#ux-design)
9. [MVP Demo Script](#mvp-demo-script)
10. [Definition of Done](#definition-of-done)

---

## Executive Summary

**RainyPost** is a 100% native macOS application built with SwiftUI + AppKit, designed as a professional API client for developers. The MVP focuses on solo-dev workflows with a clear path to Teams/Enterprise features in future versions.

### Core Principles
- **Offline-first**: Full functionality without internet or accounts
- **Files as Source of Truth**: Human-readable workspace files (JSON/YAML)
- **SwiftData as Index**: Fast search, history, recents—not source of truth
- **Security-first**: Secrets in Keychain only, never in workspace files
- **Premium UX**: Feels like a polished macOS citizen

---

## Development Phases

| Phase | Name | Duration | Focus |
|-------|------|----------|-------|
| **1** | Foundation & Core Architecture | 3 weeks | Project structure, models, persistence layer |
| **2** | Request Builder & Execution | 3 weeks | Full request lifecycle, auth methods |
| **3** | Environments & Variables | 2 weeks | Variable system with scopes and interpolation |
| **4** | Response Viewer & History | 2 weeks | Response display, SwiftData index, search |
| **5** | Import/Export & Polish | 2 weeks | Postman/OpenAPI import, export, cURL |
| **6** | QA, Performance & Release | 2 weeks | Testing, optimization, release preparation |

**Total Estimated Duration**: 14 weeks (~3.5 months)

---

### Phase 1: Foundation & Core Architecture

**Objective**: Establish solid architectural foundation with all core layers.

**Scope**:
- Xcode project restructuring into modular architecture
- Core domain models (Workspace, Collection, Folder, Request, Environment)
- File-based persistence layer (WorkspaceFS)
- SwiftData schema and index layer
- Keychain wrapper for secrets
- Basic UI shell (sidebar + main content)

**Entregables**:
- [ ] Modular project structure with clear layer separation
- [ ] `WorkspaceManager` for file operations with atomic writes
- [ ] `SwiftDataIndex` schema and sync mechanism
- [ ] `KeychainService` wrapper with CRUD operations
- [ ] Basic navigation shell UI

**Risks**:
| Risk | Mitigation |
|------|------------|
| SwiftData limitations for indexing | Design with fallback to SQLite if needed |
| File watcher performance | Throttle with debounce, use FSEvents efficiently |

**Metrics**:
- Startup time < 500ms (empty workspace)
- File operations < 100ms for typical workspace

**Definition of Done**:
- Can create/open workspace folder
- Models serialize to/from JSON correctly
- Keychain stores/retrieves test secrets
- SwiftData indexes test data
- Basic sidebar shows workspace structure

---

### Phase 2: Request Builder & Execution

**Objective**: Complete request building and HTTP execution engine.

**Scope**:
- Request builder UI (method, URL, params, headers, body)
- Body types: raw JSON, text, form-urlencoded, multipart/form-data
- File upload support for multipart
- Auth methods: Bearer, Basic, API Key, Manual OAuth paste
- URLSession-based networking layer with interceptors
- Request validation and error handling

**Entregables**:
- [ ] `RequestBuilder` SwiftUI view with all input types
- [ ] `HTTPEngine` with URLSession, interceptors, and cookie handling
- [ ] `AuthProvider` protocol with implementations
- [ ] File picker integration for multipart uploads
- [ ] Request validation layer

**Risks**:
| Risk | Mitigation |
|------|------------|
| Complex body encoding | Use Foundation's URLComponents + custom encoder |
| Cookie handling across requests | Implement CookieJar per workspace |

**Metrics**:
- Request execution < 50ms overhead (excluding network latency)
- Memory stable with 1000+ request executions

**Definition of Done**:
- Can build and execute GET/POST/PUT/PATCH/DELETE requests
- All body types work correctly
- All auth methods work correctly
- Multipart file upload works
- Cookies persist per workspace

---

### Phase 3: Environments & Variables

**Objective**: Full variable system with scopes and interpolation.

**Scope**:
- Environment model and UI
- Variable scopes: workspace → folder → request (cascade override)
- `{{variable}}` interpolation in URL, headers, body
- Secret variable references (stored in Keychain)
- Environment switcher UI

**Entregables**:
- [ ] `Environment` model and persistence
- [ ] `VariableInterpolator` engine with scope resolution
- [ ] `SecretRef` type for Keychain references
- [ ] Environment selector dropdown
- [ ] Variable editor with inline preview

**Risks**:
| Risk | Mitigation |
|------|------------|
| Circular variable references | Detect cycles, max 10 depth |
| Performance with many variables | Cache resolved values, invalidate on change |

**Metrics**:
- Variable interpolation < 5ms for typical request
- Environment switching < 100ms

**Definition of Done**:
- Can create/edit environments with variables
- Variables interpolate correctly in URL, headers, body
- Scope override works (request > folder > workspace)
- Secrets reference Keychain correctly
- Quick-switch environments from toolbar

---

### Phase 4: Response Viewer & History

**Objective**: Rich response display and searchable history.

**Scope**:
- Response viewer: pretty JSON, raw, headers, status, timing
- JSON syntax highlighting and collapsible tree
- Save response to file
- History model with SwiftData index
- Search across history (URL, status, date range)
- Recent requests quick access

**Entregables**:
- [ ] `ResponseViewer` with tabbed display
- [ ] `JSONTreeView` with syntax highlighting
- [ ] `HistoryEntry` SwiftData model
- [ ] `HistorySearch` with predicates
- [ ] "Recents" sidebar section

**Risks**:
| Risk | Mitigation |
|------|------------|
| Large response bodies (>10MB) | Lazy loading, truncation with "show more" |
| History database size | Pruning policy (keep last 1000 or 30 days) |

**Metrics**:
- JSON render < 100ms for 1MB response
- History search < 50ms for 10,000 entries

**Definition of Done**:
- Response shows status, timing, headers, body
- JSON is pretty-printed with syntax highlighting
- Can save response to file
- History records all executions
- Can search history by URL pattern

---

### Phase 5: Import/Export & Polish

**Objective**: Interoperability and final polish.

**Scope**:
- Import Postman collections (v2.1)
- Import OpenAPI 3.0 specs (basic)
- Export to cURL command
- Export workspace as ZIP (without secrets)
- UI polish: keyboard shortcuts, command palette
- Accessibility audit and fixes

**Entregables**:
- [ ] `PostmanImporter` for collections v2.1
- [ ] `OpenAPIImporter` for basic specs
- [ ] `CurlExporter` for requests
- [ ] `WorkspaceExporter` for ZIP backup
- [ ] Command palette with fuzzy search
- [ ] Full keyboard navigation

**Risks**:
| Risk | Mitigation |
|------|------------|
| Postman format variations | Handle gracefully, log warnings |
| OpenAPI complexity | MVP: basic endpoints only, no advanced features |

**Metrics**:
- Import 100 requests < 2s
- Export workspace < 1s

**Definition of Done**:
- Import Postman collection creates valid requests
- Import OpenAPI creates valid requests
- Export cURL works for all request types
- Export ZIP excludes secrets
- Command palette navigates all features

---

### Phase 6: QA, Performance & Release

**Objective**: Production-ready quality and release preparation.

**Scope**:
- Comprehensive unit/integration test suite
- UI test automation for critical flows
- Performance optimization and profiling
- Memory leak detection
- Crash reporting setup
- App Store preparation (icons, screenshots, metadata)

**Entregables**:
- [ ] 80%+ test coverage on core logic
- [ ] UI tests for MVP demo flow
- [ ] Performance report meeting budgets
- [ ] Zero critical bugs
- [ ] App Store assets ready

**Risks**:
| Risk | Mitigation |
|------|------------|
| Performance regressions | CI performance benchmarks |
| Undiscovered edge cases | Beta testing program |

**Metrics**:
- Startup: < 1s cold, < 300ms warm
- Memory: < 200MB idle, < 500MB with large workspace
- CPU: < 5% idle, < 30% during request execution

**Definition of Done**:
- All tests pass
- Performance budgets met
- Zero P0/P1 bugs
- App runs smoothly on macOS 14+
- Ready for App Store submission

---

## Technical Architecture

### Layer Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                           UI Layer                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐  │
│  │  Requests   │ │ Collections │ │Environments │ │  History  │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └───────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                        Domain Layer                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Use Cases: ExecuteRequest, ManageWorkspace, InterpolateVars│ │
│  │  Entities: Request, Collection, Environment, Variable       │ │
│  └─────────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────────┤
│                         Data Layer                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │   WorkspaceFS    │  │  SwiftDataIndex  │  │KeychainService │ │
│  │(JSON/YAML files) │  │ (cache/search)   │  │  (secrets)     │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                       Services Layer                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐  │
│  │ HTTPEngine  │ │ FileWatcher │ │  Importers  │ │ Exporters │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └───────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| **UI Layer** | SwiftUI views, ViewModels, user interaction |
| **Domain Layer** | Business logic, entities, use cases |
| **Data Layer** | Persistence (files + SwiftData + Keychain) |
| **Services Layer** | HTTP networking, file watching, import/export |

---

## Data Models

### Entity Relationship Diagram

```
┌──────────────┐
│  Workspace   │
│──────────────│
│ id: UUID     │
│ name: String │
│ path: URL    │
│ createdAt    │
│ updatedAt    │
└──────┬───────┘
       │ 1:N
       ▼
┌──────────────┐      ┌──────────────┐
│  Collection  │      │ Environment  │
│──────────────│      │──────────────│
│ id: UUID     │      │ id: UUID     │
│ name: String │      │ name: String │
│ parentId?    │◄────▶│ isActive     │
└──────┬───────┘      │ variables[]  │
       │ 1:N          └──────────────┘
       ▼
┌──────────────┐      ┌──────────────┐
│   Folder     │      │   Variable   │
│──────────────│      │──────────────│
│ id: UUID     │      │ key: String  │
│ name: String │      │ value: String│
│ parentId?    │      │ isSecret     │
└──────┬───────┘      │ secretRef?   │
       │ 1:N          └──────────────┘
       ▼
┌──────────────┐      ┌──────────────┐
│   Request    │      │  SecretRef   │
│──────────────│      │──────────────│
│ id: UUID     │      │ keychainId   │
│ name: String │      │ service      │
│ method       │      │ account      │
│ url: String  │      └──────────────┘
│ headers[]    │
│ queryParams[]│      ┌──────────────┐
│ body         │      │ HistoryEntry │
│ auth         │      │──────────────│
│ variables[]  │      │ id: UUID     │
└──────────────┘      │ requestId    │
                      │ url: String  │
                      │ method       │
                      │ status: Int  │
                      │ duration: ms │
                      │ timestamp    │
                      │ responseSize │
                      └──────────────┘
```

### Swift Model Definitions

```swift
// MARK: - Workspace
struct Workspace: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String?
    let createdAt: Date
    var updatedAt: Date
    var settings: WorkspaceSettings
}

struct WorkspaceSettings: Codable {
    var defaultEnvironmentId: UUID?
    var timeout: Int = 30000 // ms
    var followRedirects: Bool = true
    var validateSSL: Bool = true
}

// MARK: - Collection
struct Collection: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String?
    var parentId: UUID? // For nested collections
    let createdAt: Date
    var updatedAt: Date
}

// MARK: - Request
struct Request: Identifiable, Codable {
    let id: UUID
    var name: String
    var method: HTTPMethod
    var url: String
    var headers: [Header]
    var queryParams: [QueryParam]
    var body: RequestBody?
    var auth: AuthConfig?
    var variables: [Variable] // Request-level overrides
    var collectionId: UUID?
    var folderId: UUID?
    let createdAt: Date
    var updatedAt: Date
}

enum HTTPMethod: String, Codable, CaseIterable {
    case GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
}

struct Header: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isEnabled: Bool = true
}

struct QueryParam: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isEnabled: Bool = true
}

// MARK: - Request Body
enum RequestBody: Codable {
    case none
    case raw(content: String, contentType: RawContentType)
    case formUrlEncoded(params: [FormParam])
    case multipart(parts: [MultipartPart])
}

enum RawContentType: String, Codable {
    case json = "application/json"
    case text = "text/plain"
    case xml = "application/xml"
    case html = "text/html"
}

struct FormParam: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isEnabled: Bool = true
}

struct MultipartPart: Identifiable, Codable {
    let id: UUID
    var key: String
    var type: MultipartType
    var isEnabled: Bool = true
}

enum MultipartType: Codable {
    case text(value: String)
    case file(path: String, mimeType: String?)
}

// MARK: - Authentication
enum AuthConfig: Codable {
    case none
    case bearer(token: SecretRef)
    case basic(username: String, password: SecretRef)
    case apiKey(key: String, value: SecretRef, location: APIKeyLocation)
    case manualOAuth(token: SecretRef)
}

enum APIKeyLocation: String, Codable {
    case header, query
}

// MARK: - Environment & Variables
struct Environment: Identifiable, Codable {
    let id: UUID
    var name: String
    var variables: [Variable]
    var isActive: Bool = false
    let createdAt: Date
    var updatedAt: Date
}

struct Variable: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isSecret: Bool = false
    var secretRef: SecretRef?
    var isEnabled: Bool = true
}

// MARK: - Secret Reference
struct SecretRef: Codable, Hashable {
    let keychainId: String // UUID stored in file
    let service: String = "com.rainypost.secrets"
    var account: String { keychainId }
}

// MARK: - History (SwiftData)
@Model
final class HistoryEntry {
    @Attribute(.unique) var id: UUID
    var requestId: UUID
    var requestName: String
    var url: String
    var method: String
    var statusCode: Int?
    var duration: Int // milliseconds
    var responseSize: Int // bytes
    var timestamp: Date
    var workspaceId: UUID
    
    // Searchable fields
    @Attribute(.spotlight) var searchableUrl: String
    @Attribute(.spotlight) var searchableName: String
}

// MARK: - Search Index (SwiftData)
@Model
final class RequestIndex {
    @Attribute(.unique) var id: UUID
    var name: String
    var url: String
    var method: String
    var collectionId: UUID?
    var workspaceId: UUID
    var lastModified: Date
    var fileHash: String // For sync detection
    
    @Attribute(.spotlight) var searchableContent: String
}
```

---

## Persistence Strategy

### Workspace Folder Structure

```
MyWorkspace/
├── workspace.json           # Workspace metadata & settings
├── environments/
│   ├── development.env.json
│   ├── staging.env.json
│   └── production.env.json
├── collections/
│   └── api-v1/
│       ├── collection.json  # Collection metadata
│       ├── auth/
│       │   ├── folder.json
│       │   ├── login.request.json
│       │   └── logout.request.json
│       └── users/
│           ├── folder.json
│           ├── get-user.request.json
│           └── create-user.request.json
└── .rainypost/              # Hidden metadata
    ├── index.db             # SwiftData store
    └── cache/               # Response cache (optional)
```

### File Format Examples

**workspace.json**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "My API Project",
  "version": "1.0",
  "description": "Main backend API testing",
  "settings": {
    "defaultEnvironmentId": "env-uuid-here",
    "timeout": 30000,
    "followRedirects": true,
    "validateSSL": true
  },
  "createdAt": "2026-01-04T00:00:00Z",
  "updatedAt": "2026-01-04T12:00:00Z"
}
```

**request.json**:
```json
{
  "id": "request-uuid",
  "name": "Get User by ID",
  "method": "GET",
  "url": "{{baseUrl}}/users/{{userId}}",
  "headers": [
    { "id": "h1", "key": "Authorization", "value": "Bearer {{authToken}}", "isEnabled": true },
    { "id": "h2", "key": "Accept", "value": "application/json", "isEnabled": true }
  ],
  "queryParams": [],
  "body": { "type": "none" },
  "auth": { "type": "bearer", "tokenRef": "keychain:auth-token-id" },
  "variables": [],
  "createdAt": "2026-01-04T00:00:00Z",
  "updatedAt": "2026-01-04T12:00:00Z"
}
```

**environment.json**:
```json
{
  "id": "env-uuid",
  "name": "Development",
  "variables": [
    { "id": "v1", "key": "baseUrl", "value": "https://api.dev.example.com", "isSecret": false },
    { "id": "v2", "key": "authToken", "value": "", "isSecret": true, "secretRef": "keychain:dev-auth-token" }
  ],
  "isActive": true,
  "createdAt": "2026-01-04T00:00:00Z",
  "updatedAt": "2026-01-04T12:00:00Z"
}
```

### Files ↔ SwiftData Synchronization

#### Sync Algorithm

```swift
class WorkspaceSyncManager {
    /// Sync strategy: Files always win, DB is read-only cache
    
    func performSync(workspace: Workspace) async throws {
        // 1. Scan workspace directory for all .json files
        let diskFiles = try await scanWorkspaceFiles(at: workspace.path)
        
        // 2. Compare with indexed files using hash/timestamp
        let indexedFiles = try await fetchIndexedFiles(for: workspace.id)
        
        // 3. Determine changes
        let changes = diffFiles(disk: diskFiles, indexed: indexedFiles)
        
        // 4. Apply changes to SwiftData
        for file in changes.added {
            try await indexFile(file)
        }
        for file in changes.modified {
            try await reindexFile(file)
        }
        for file in changes.deleted {
            try await removeFromIndex(file)
        }
    }
    
    private func diffFiles(disk: [FileInfo], indexed: [IndexedFile]) -> FileChanges {
        // Compare by:
        // 1. File existence (added/deleted)
        // 2. Last modified timestamp OR content hash
        // Use content hash for reliability, timestamp for performance
    }
}

struct FileInfo {
    let path: URL
    let modifiedAt: Date
    let contentHash: String // SHA256
}
```

#### Conflict Resolution Policy

| Scenario | Resolution |
|----------|------------|
| File changed on disk | Reindex from file (files win) |
| File deleted on disk | Remove from SwiftData index |
| SwiftData has entry, no file | Remove orphan index entry |
| File corrupted/invalid JSON | Log warning, skip file, mark in UI |

#### File Watcher Implementation

```swift
class FileWatcher {
    private var eventStream: FSEventStreamRef?
    private let debouncer = Debouncer(delay: 0.5) // 500ms debounce
    
    func watch(directory: URL, onChange: @escaping (URL) -> Void) {
        let context = FSEventStreamContext(...)
        
        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { (_, _, numEvents, eventPaths, eventFlags, eventIds) in
                // Process events
                self.debouncer.debounce {
                    onChange(changedURL)
                }
            },
            &context,
            [directory.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.3, // Latency
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )
        
        FSEventStreamScheduleWithRunLoop(eventStream!, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(eventStream!)
    }
}
```

---

## Project Structure

```
RainyPost/
├── RainyPost.xcodeproj/
├── RainyPost/
│   ├── App/
│   │   ├── RainyPostApp.swift          # @main entry point
│   │   ├── AppDelegate.swift           # AppKit delegate for menu, etc.
│   │   ├── AppState.swift              # Global app state
│   │   └── WindowManager.swift         # Window management
│   │
│   ├── Features/
│   │   ├── Workspace/
│   │   │   ├── Views/
│   │   │   │   ├── WorkspacePickerView.swift
│   │   │   │   └── WorkspaceSidebarView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── WorkspaceViewModel.swift
│   │   │   └── Models/
│   │   │       └── WorkspaceState.swift
│   │   │
│   │   ├── Requests/
│   │   │   ├── Views/
│   │   │   │   ├── RequestBuilderView.swift
│   │   │   │   ├── RequestMethodPicker.swift
│   │   │   │   ├── URLInputView.swift
│   │   │   │   ├── HeadersEditor.swift
│   │   │   │   ├── QueryParamsEditor.swift
│   │   │   │   ├── BodyEditor/
│   │   │   │   │   ├── BodyEditorView.swift
│   │   │   │   │   ├── RawBodyEditor.swift
│   │   │   │   │   ├── FormUrlEncodedEditor.swift
│   │   │   │   │   └── MultipartEditor.swift
│   │   │   │   └── AuthConfigView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── RequestViewModel.swift
│   │   │   └── Models/
│   │   │       └── RequestEditorState.swift
│   │   │
│   │   ├── Response/
│   │   │   ├── Views/
│   │   │   │   ├── ResponseViewerView.swift
│   │   │   │   ├── JSONTreeView.swift
│   │   │   │   ├── RawResponseView.swift
│   │   │   │   ├── HeadersResponseView.swift
│   │   │   │   └── TimingView.swift
│   │   │   └── ViewModels/
│   │   │       └── ResponseViewModel.swift
│   │   │
│   │   ├── Collections/
│   │   │   ├── Views/
│   │   │   │   ├── CollectionListView.swift
│   │   │   │   ├── CollectionTreeItem.swift
│   │   │   │   └── FolderView.swift
│   │   │   └── ViewModels/
│   │   │       └── CollectionViewModel.swift
│   │   │
│   │   ├── Environments/
│   │   │   ├── Views/
│   │   │   │   ├── EnvironmentPickerView.swift
│   │   │   │   ├── EnvironmentEditorView.swift
│   │   │   │   └── VariableEditorRow.swift
│   │   │   └── ViewModels/
│   │   │       └── EnvironmentViewModel.swift
│   │   │
│   │   ├── History/
│   │   │   ├── Views/
│   │   │   │   ├── HistoryListView.swift
│   │   │   │   └── HistorySearchView.swift
│   │   │   └── ViewModels/
│   │   │       └── HistoryViewModel.swift
│   │   │
│   │   └── ImportExport/
│   │       ├── Views/
│   │       │   ├── ImportWizardView.swift
│   │       │   └── ExportOptionsView.swift
│   │       ├── Importers/
│   │       │   ├── PostmanImporter.swift
│   │       │   └── OpenAPIImporter.swift
│   │       └── Exporters/
│   │           ├── CurlExporter.swift
│   │           └── WorkspaceExporter.swift
│   │
│   ├── Core/
│   │   ├── Domain/
│   │   │   ├── Models/
│   │   │   │   ├── Workspace.swift
│   │   │   │   ├── Collection.swift
│   │   │   │   ├── Request.swift
│   │   │   │   ├── Environment.swift
│   │   │   │   ├── Variable.swift
│   │   │   │   ├── AuthConfig.swift
│   │   │   │   └── SecretRef.swift
│   │   │   ├── UseCases/
│   │   │   │   ├── ExecuteRequestUseCase.swift
│   │   │   │   ├── InterpolateVariablesUseCase.swift
│   │   │   │   └── ManageWorkspaceUseCase.swift
│   │   │   └── Protocols/
│   │   │       ├── WorkspaceRepository.swift
│   │   │       └── SecretStorage.swift
│   │   │
│   │   ├── Persistence/
│   │   │   ├── WorkspaceFS/
│   │   │   │   ├── WorkspaceFileManager.swift
│   │   │   │   ├── FileWatcher.swift
│   │   │   │   ├── JSONFileHandler.swift
│   │   │   │   └── AtomicFileWriter.swift
│   │   │   ├── SwiftDataIndex/
│   │   │   │   ├── IndexSchema.swift
│   │   │   │   ├── HistoryEntry.swift
│   │   │   │   ├── RequestIndex.swift
│   │   │   │   └── SyncManager.swift
│   │   │   └── Keychain/
│   │   │       ├── KeychainService.swift
│   │   │       └── SecretManager.swift
│   │   │
│   │   ├── Networking/
│   │   │   ├── HTTPEngine.swift
│   │   │   ├── RequestInterceptor.swift
│   │   │   ├── ResponseInterceptor.swift
│   │   │   ├── CookieJar.swift
│   │   │   └── SSLPinning.swift
│   │   │
│   │   └── Utils/
│   │       ├── VariableInterpolator.swift
│   │       ├── Debouncer.swift
│   │       ├── HashUtils.swift
│   │       └── DateFormatters.swift
│   │
│   ├── DesignSystem/
│   │   ├── Theme/
│   │   │   ├── AppTheme.swift
│   │   │   ├── Colors.swift
│   │   │   └── Typography.swift
│   │   ├── Components/
│   │   │   ├── RPButton.swift
│   │   │   ├── RPTextField.swift
│   │   │   ├── RPDropdown.swift
│   │   │   ├── RPCodeEditor.swift
│   │   │   ├── RPSplitView.swift
│   │   │   └── RPTabView.swift
│   │   └── Icons/
│   │       └── RPIcons.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   ├── Localizable.strings
│   │   └── Info.plist
│   │
│   └── Preview Content/
│       └── PreviewData.swift
│
├── RainyPostTests/
│   ├── Core/
│   │   ├── VariableInterpolatorTests.swift
│   │   ├── WorkspaceFileManagerTests.swift
│   │   ├── JSONFileHandlerTests.swift
│   │   └── HTTPEngineTests.swift
│   ├── Importers/
│   │   ├── PostmanImporterTests.swift
│   │   └── OpenAPIImporterTests.swift
│   ├── Exporters/
│   │   └── CurlExporterTests.swift
│   └── Mocks/
│       ├── MockHTTPClient.swift
│       └── MockKeychain.swift
│
├── RainyPostUITests/
│   ├── DemoFlowUITest.swift
│   ├── RequestBuilderUITests.swift
│   └── EnvironmentSwitchUITests.swift
│
└── RainyPostIntegrationTests/
    ├── LocalMockServer/
    │   └── MockServer.swift
    └── EndToEndTests.swift
```

### Structure Justification

| Directory | Purpose |
|-----------|---------|
| `App/` | Application lifecycle, window management, global state |
| `Features/` | Feature-based modules, each self-contained with Views/ViewModels |
| `Core/Domain/` | Business entities and use cases, framework-agnostic |
| `Core/Persistence/` | All persistence: files, SwiftData, Keychain |
| `Core/Networking/` | HTTP engine with interceptors, cookies, SSL |
| `DesignSystem/` | Reusable UI components, theming, typography |
| `Tests/` | Unit tests organized by module |
| `UITests/` | Automated UI tests for critical flows |

---

## QA & Testing Plan

### Test Categories

#### 1. Unit Tests

**Target Coverage**: 80%+ on Core logic

| Module | Test Focus | Priority |
|--------|------------|----------|
| `VariableInterpolator` | Template parsing, scope resolution, cycles | P0 |
| `JSONFileHandler` | Serialization, deserialization, error handling | P0 |
| `CurlExporter` | All request types, escaping, multipart | P0 |
| `PostmanImporter` | Collection v2.1 parsing, edge cases | P1 |
| `OpenAPIImporter` | Basic spec parsing, path params | P1 |
| `HTTPEngine` | Request building, timeout, cancellation | P1 |
| `SyncManager` | File diff, hash comparison, conflict resolution | P1 |

**Example Test Cases for VariableInterpolator**:

```swift
class VariableInterpolatorTests: XCTestCase {
    func testSimpleInterpolation() {
        let vars = ["baseUrl": "https://api.example.com"]
        let result = interpolator.interpolate("{{baseUrl}}/users", with: vars)
        XCTAssertEqual(result, "https://api.example.com/users")
    }
    
    func testNestedVariables() {
        let vars = ["domain": "example.com", "baseUrl": "https://{{domain}}"]
        let result = interpolator.interpolate("{{baseUrl}}/users", with: vars)
        XCTAssertEqual(result, "https://example.com/users")
    }
    
    func testCircularReferenceDetection() {
        let vars = ["a": "{{b}}", "b": "{{a}}"]
        XCTAssertThrowsError(try interpolator.interpolate("{{a}}", with: vars)) { error in
            XCTAssert(error is InterpolationError.circularReference)
        }
    }
    
    func testMissingVariableKept() {
        let result = interpolator.interpolate("{{unknown}}/path", with: [:])
        XCTAssertEqual(result, "{{unknown}}/path")
    }
    
    func testScopeOverride() {
        let workspaceVars = ["env": "prod"]
        let requestVars = ["env": "dev"]
        let result = interpolator.interpolate("{{env}}", 
            workspaceVariables: workspaceVars,
            requestVariables: requestVars)
        XCTAssertEqual(result, "dev") // Request overrides
    }
}
```

#### 2. Integration Tests (Mock Server)

**Setup**: Local mock server using Swift NIO or Embassy

```swift
class LocalMockServer {
    func start(port: Int = 8080) async throws
    func stop() async
    
    // Route handlers
    func whenGET(_ path: String, respond: @escaping () -> MockResponse)
    func whenPOST(_ path: String, respond: @escaping (Data) -> MockResponse)
}

class HTTPEngineIntegrationTests: XCTestCase {
    var server: LocalMockServer!
    var engine: HTTPEngine!
    
    override func setUp() async throws {
        server = LocalMockServer()
        try await server.start()
        engine = HTTPEngine()
    }
    
    func testGetRequest() async throws {
        server.whenGET("/users/1") {
            MockResponse(status: 200, json: ["id": 1, "name": "John"])
        }
        
        let request = Request(method: .GET, url: "http://localhost:8080/users/1")
        let response = try await engine.execute(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.body.contains("John"))
    }
    
    func testPostWithBody() async throws {
        server.whenPOST("/users") { body in
            let json = try! JSONSerialization.jsonObject(with: body) as! [String: Any]
            XCTAssertEqual(json["name"] as? String, "Jane")
            return MockResponse(status: 201, json: ["id": 2, "name": "Jane"])
        }
        
        let request = Request(
            method: .POST, 
            url: "http://localhost:8080/users",
            body: .raw(content: "{\"name\":\"Jane\"}", contentType: .json)
        )
        let response = try await engine.execute(request)
        
        XCTAssertEqual(response.statusCode, 201)
    }
    
    func testTimeoutHandling() async throws {
        server.whenGET("/slow") {
            Thread.sleep(forTimeInterval: 5)
            return MockResponse(status: 200)
        }
        
        let request = Request(method: .GET, url: "http://localhost:8080/slow")
        engine.timeout = 1.0
        
        do {
            _ = try await engine.execute(request)
            XCTFail("Should have timed out")
        } catch HTTPError.timeout {
            // Expected
        }
    }
}
```

#### 3. UI Tests (Critical Flows)

**MVP Demo Flow Test**:

```swift
class DemoFlowUITest: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting", "--clean-state"]
        app.launch()
    }
    
    func testMVPDemoFlow() {
        // 1. Create new workspace
        app.buttons["Create Workspace"].click()
        app.textFields["Workspace Name"].typeText("Demo Workspace")
        app.buttons["Create"].click()
        
        // 2. Create environment
        app.buttons["Add Environment"].click()
        app.textFields["Environment Name"].typeText("Development")
        app.buttons["Add Variable"].click()
        app.cells.textFields["Key"].typeText("baseUrl")
        app.cells.textFields["Value"].typeText("https://jsonplaceholder.typicode.com")
        app.buttons["Save"].click()
        
        // 3. Create request
        app.buttons["New Request"].click()
        app.textFields["Request Name"].typeText("Get Users")
        app.popUpButtons["Method"].click()
        app.menuItems["GET"].click()
        app.textFields["URL"].typeText("{{baseUrl}}/users")
        app.buttons["Save Request"].click()
        
        // 4. Execute request
        app.buttons["Send"].click()
        
        // 5. Verify response
        XCTAssertTrue(app.staticTexts["200 OK"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["application/json"].exists)
        
        // 6. Export to cURL
        app.buttons["Export"].click()
        app.menuItems["Copy as cURL"].click()
        
        // Verify clipboard contains cURL
        let pasteboard = NSPasteboard.general
        let curlCommand = pasteboard.string(forType: .string)
        XCTAssertTrue(curlCommand?.contains("curl") ?? false)
    }
}
```

### Performance Budget

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Cold Startup** | < 1.0s | Time from launch to interactive |
| **Warm Startup** | < 300ms | Already cached in memory |
| **Request Execution Overhead** | < 50ms | Excluding network time |
| **JSON Render (1MB)** | < 100ms | Time to display formatted JSON |
| **History Search (10k entries)** | < 50ms | Query response time |
| **Memory (Idle)** | < 200MB | Empty workspace open |
| **Memory (Active)** | < 500MB | Large workspace, 100 tabs |
| **CPU (Idle)** | < 5% | No active requests |
| **File Sync (1000 requests)** | < 5s | Full reindex |

### Test Execution Commands

```bash
# Unit Tests
xcodebuild test \
  -scheme RainyPost \
  -destination 'platform=macOS' \
  -only-testing:RainyPostTests

# Integration Tests (requires mock server)
xcodebuild test \
  -scheme RainyPost \
  -destination 'platform=macOS' \
  -only-testing:RainyPostIntegrationTests

# UI Tests
xcodebuild test \
  -scheme RainyPost \
  -destination 'platform=macOS' \
  -only-testing:RainyPostUITests

# Performance Tests
xcodebuild test \
  -scheme RainyPost \
  -destination 'platform=macOS' \
  -only-testing:RainyPostTests/PerformanceTests

# All Tests with Coverage
xcodebuild test \
  -scheme RainyPost \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES
```

---

## UX Design

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  🌧️ RainyPost                    [Environment ▾]  [🔍]  [⌘K]              │
├───────────────┬─────────────────────────────────────────────────────────────┤
│               │  ┌─────────────────────────────────────────────────────────┐│
│   WORKSPACE   │  │ GET ▾ │ {{baseUrl}}/users/{{id}}                  [Send]││
│   ───────────│  ├─────────────────────────────────────────────────────────┤│
│   📁 API v1  │  │ Params │ Headers │ Auth │ Body                         ││
│   ├─ 📂 Auth  │  │─────────────────────────────────────────────────────────││
│   │  └─ 🔵 Login │  │ Key          │ Value          │ □ enabled           ││
│   ├─ 📂 Users│  │ id           │ {{userId}}     │ ☑                     ││
│   │  ├─ 🟢 Get   │  │ [+ Add Param]                                        ││
│   │  └─ 🟡 Create│  └─────────────────────────────────────────────────────────┘│
│   │           │                                                            │
│   ├─ ENVS     │  ┌─────────────────────────────────────────────────────────┐│
│   │ ● Dev     │  │ Response                                    [Save] [⋯] ││
│   │ ○ Staging │  ├─────────────────────────────────────────────────────────┤│
│   │ ○ Prod    │  │ Body │ Headers │ Timing                                ││
│   │           │  │─────────────────────────────────────────────────────────││
│   ├─ HISTORY  │  │ 200 OK  •  245ms  •  1.2 KB                            ││
│   │ ↻ GET /users │  │─────────────────────────────────────────────────────────││
│   │ ↻ POST /login│  │ {                                                      ││
│   └─────────────│  │   "id": 1, ▾                                          ││
│               │  │   "name": "John Doe",                                  ││
│               │  │   "email": "john@example.com"                          ││
│               │  │ }                                                       ││
│               │  └─────────────────────────────────────────────────────────┘│
├───────────────┴─────────────────────────────────────────────────────────────┤
│  Ready  •  Last saved 2m ago  •  Development                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key UI Components

| Component | Description |
|-----------|-------------|
| **Sidebar** | Collapsible tree: Collections > Folders > Requests + Environments + History |
| **Request Builder** | Tabbed interface: Params, Headers, Auth, Body |
| **Response Viewer** | Tabbed: Body (Pretty/Raw), Headers, Timing |
| **Environment Picker** | Dropdown in toolbar for quick switch |
| **Command Palette** | ⌘K for fuzzy search across all actions |
| **Status Bar** | Save status, current environment, sync status |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘N` | New Request |
| `⌘⇧N` | New Collection |
| `⌘↵` | Send Request |
| `⌘E` | Switch Environment |
| `⌘K` | Command Palette |
| `⌘,` | Preferences |
| `⌘S` | Save (autosave enabled by default) |
| `⌘⇧C` | Copy as cURL |
| `⌘⇧I` | Import |
| `⌘⇧E` | Export |
| `⌘1-9` | Switch tabs |
| `⌘[` / `⌘]` | Navigate back/forward |
| `⌘F` | Search in response |
| `⌘⇧F` | Search in workspace |

### Accessibility

- Full VoiceOver support with semantic labels
- Dynamic Type for adjustable font sizes
- High Contrast mode support
- Keyboard-only navigation for all features
- Minimum 4.5:1 contrast ratios
- Focus indicators on all interactive elements

### Quick Request Mode

For rapid testing without saving:

```
┌─────────────────────────────────────────────────────────────────┐
│ Quick Request (⌘T)                                      [×]    │
├─────────────────────────────────────────────────────────────────┤
│ GET ▾ │ https://api.example.com/endpoint           [Send ⌘↵]  │
│                                                               │
│ Response: 200 OK • 127ms                                      │
│ {"status": "ok"}                                              │
│                                                               │
│ [Save to Collection...]                      [Copy as cURL]  │
└─────────────────────────────────────────────────────────────────┘
```

---

## MVP Demo Script

### Pre-Demo Setup
1. Clean install of RainyPost
2. No existing workspaces
3. Network connectivity for live API calls

### Demo Steps (~5 minutes)

**Step 1: Create Workspace (30s)**
1. Launch RainyPost
2. Click "Create New Workspace"
3. Name: "Demo API Project"
4. Choose save location
5. ✓ Workspace created with default structure

**Step 2: Configure Environment (45s)**
1. Click "+" next to Environments
2. Name: "JSONPlaceholder"
3. Add variable: `baseUrl` = `https://jsonplaceholder.typicode.com`
4. Add secret variable: `apiKey` → Keychain prompt
5. Set as active environment
6. ✓ Environment badge shows "JSONPlaceholder"

**Step 3: Create First Request (60s)**
1. Click "New Request"
2. Name: "Get All Users"
3. Method: GET
4. URL: `{{baseUrl}}/users`
5. Show variable highlighting in URL
6. Press ⌘↵ (Send)
7. ✓ See 200 OK, 10 users returned

**Step 4: Create POST Request (60s)**
1. Click "New Request"
2. Name: "Create User"
3. Method: POST
4. URL: `{{baseUrl}}/users`
5. Add Header: `Content-Type: application/json`
6. Select Body > Raw > JSON
7. Type: `{"name": "Demo User", "email": "demo@test.com"}`
8. Press ⌘↵ (Send)
9. ✓ See 201 Created with new user ID

**Step 5: Inspect Response (45s)**
1. Expand JSON tree view
2. Show collapsible sections
3. Click "Headers" tab → show response headers
4. Click "Timing" tab → show request phases
5. Click "Copy" → paste formatted JSON

**Step 6: View History (30s)**
1. Expand History in sidebar
2. Show recent requests
3. Click on previous request
4. ✓ Request loads back into builder

**Step 7: Export to cURL (30s)**
1. With request selected
2. Click "Export" → "Copy as cURL"
3. Open Terminal
4. Paste and execute
5. ✓ Same response as in RainyPost

**Step 8: Close and Reopen (30s)**
1. Quit RainyPost (⌘Q)
2. Relaunch application
3. Click recent workspace
4. ✓ All requests/environments restored perfectly

### Demo Talking Points
- "Everything is stored as readable JSON files—version control friendly"
- "Secrets are stored securely in macOS Keychain, never in files"
- "Works completely offline, no account required"
- "Native macOS performance—instant response"

---

## Definition of Done

### MVP Release Criteria

#### Functional Requirements
- [ ] Can create, open, and close workspace folders
- [ ] Can create collections with nested folders
- [ ] Can create, edit, delete, and duplicate requests
- [ ] Full HTTP method support: GET, POST, PUT, PATCH, DELETE
- [ ] Query parameters builder with enable/disable
- [ ] Headers builder with enable/disable
- [ ] Cookie support (send and receive)
- [ ] Body types: none, raw (JSON/text), form-urlencoded, multipart
- [ ] File upload via multipart
- [ ] Auth: Bearer, Basic, API Key (header/query), Manual OAuth paste
- [ ] Environment management with variables
- [ ] Variable interpolation with scope override
- [ ] Secret storage in Keychain with references in files
- [ ] Response viewer: status, timing, headers, body (pretty/raw JSON)
- [ ] Save response to file
- [ ] History tracking with search
- [ ] Import Postman collection (v2.1)
- [ ] Import OpenAPI (basic, 3.0)
- [ ] Export to cURL
- [ ] Export workspace as ZIP (sans secrets)
- [ ] Autosave with atomic writes

#### Non-Functional Requirements
- [ ] Startup < 1s cold
- [ ] Request overhead < 50ms
- [ ] Memory < 200MB idle
- [ ] 80%+ test coverage on Core
- [ ] Zero P0/P1 bugs
- [ ] VoiceOver compatible
- [ ] Full keyboard navigation
- [ ] macOS 14+ support

#### Quality Gates
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] UI demo flow test passes
- [ ] Performance budgets met
- [ ] Security review completed
- [ ] Accessibility audit passed

#### Documentation
- [ ] README with installation
- [ ] Keyboard shortcuts cheatsheet
- [ ] Support contact information

---

## Appendix: Not MVP (Future Phases)

### Phase 7+: Teams & Enterprise Features
- OAuth2/OIDC PKCE flow
- Team workspaces with sync
- Role-based permissions
- SSO integration
- Admin panel
- Audit logs

### Phase 8+: Advanced Features
- Test runner (assertions, scripts)
- CI/CD integration
- Mock server
- GraphQL support
- WebSocket client
- gRPC support
- API documentation generator

---

*Document Version: 1.0*  
*Last Updated: 2026-01-04*  
*Author: Product Architecture Team*
