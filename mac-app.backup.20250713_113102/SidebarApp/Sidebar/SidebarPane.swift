import Foundation

enum SidebarPane {
    
    // MARK: Promise Section

    case promises
    case electronPromises
    
    // MARK: Account Section
    
    case userProfile
}

// MARK: - Protocol Conformances

extension SidebarPane: Equatable, Identifiable {
    var id: Self { self }
}
