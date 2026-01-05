# CHANGELOG

## v1.0.5

### Improvements
- Redesigned Welcome screen with native macOS blur effect using NSVisualEffectView
- New floating workspace picker modal with cleaner UI and better visual hierarchy
- Added workspace path preview when creating new workspaces
- Improved form layout with consistent spacing and native macOS styling
- Hidden title bar for cleaner window appearance
- Added default environment creation when creating new workspaces

### Fixes
- Fixed WorkspaceSidebarView missing closing brace causing private functions to be inside body
- Fixed ResponseViewerView struct closure issues
- Fixed workspace creation permission errors with proper sandbox entitlements
- Fixed security-scoped resource access for user-selected folders
- Added proper file access entitlements (read-write, bookmarks, network)

### Patches
- Removed decorative background elements from Welcome screen
- Cleaned up redundant background modifiers in main app window
- Improved error handling in WorkspaceManager with specific error types
- Added filesystem-safe name sanitization for workspace folders
- Added cleanup of partial workspace creation on failure
