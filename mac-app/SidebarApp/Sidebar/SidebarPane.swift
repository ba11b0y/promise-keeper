import Foundation

enum SidebarPane {
    
    // MARK: Promise Section

    case promises
    case electronPromises
    
    // MARK: General Section

    case helloWorld
    case whatsUp
    
    // MARK: Notifications Section
    case notifications
    
    // MARK: More Section
    
    case moreStuff
    
    // MARK: Account Section
    
    case userProfile
}

// MARK: - Protocol Conformances

extension SidebarPane: Equatable, Identifiable {
    var id: Self { self }
}
