import Foundation

enum SidebarPane {
    
    // MARK: Promise Section

    case promises
    
    // MARK: General Section

    case helloWorld
    case whatsUp
    
    // MARK: More Section
    
    case moreStuff
    
    // MARK: Account Section
    
    case userProfile
}

// MARK: - Protocol Conformances

extension SidebarPane: Equatable, Identifiable {
    var id: Self { self }
}
