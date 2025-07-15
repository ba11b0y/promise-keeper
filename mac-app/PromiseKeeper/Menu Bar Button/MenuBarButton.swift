import AppKit
import SwiftUI

class MenuBarButton {
    
    let statusItem: NSStatusItem
    
    init() {
        statusItem = NSStatusBar.system
            .statusItem(withLength: CGFloat(NSStatusItem.squareLength))
                
        guard let button = statusItem.button else {
            return
        }
        
        button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Promise Keeper")
        button.imagePosition = NSControl.ImagePosition.imageOnly
        button.target = self
        button.action = #selector(showMenu(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        // Initialize GlobalEventManager to start monitoring Enter key
        DispatchQueue.main.async {
            _ = GlobalEventManager.shared
            NSLog("🚀 MenuBarButton: GlobalEventManager initialized")
        }
    }
    
    // MARK: - Show Menu
    
    @objc
    func showMenu(_ sender: AnyObject?) {
        switch NSApp.currentEvent?.type {
        case .leftMouseUp:
            showPrimaryMenu()
        case .rightMouseUp:
            showSecondaryMenu()
        default:
            break
        }
    }
    
    func showPrimaryMenu() {
        let hostingView = NSHostingView(rootView: MenuBarPopup())
        hostingView.frame.size = hostingView.fittingSize
        
        let menu = NSMenu()
        let item = NSMenuItem()
        item.view = hostingView
        menu.addItem(item)
        showStatusItemMenu(menu)
    }
        
    func showSecondaryMenu() {
        let menu = NSMenu()
        addItem("Show Promise Keeper", action: #selector(showApp), key: "", to: menu)
        addItem("Add Promise", action: #selector(addPromise), key: "", to: menu)
        addItem("Take Screenshot Now", action: #selector(takeScreenshot), key: "", to: menu)
        menu.addItem(NSMenuItem.separator())
        addItem("About...", action: #selector(showAbout), key: "", to: menu)
        menu.addItem(NSMenuItem.separator())
        addItem("Quit", action: #selector(quit), key: "q", to: menu)
        showStatusItemMenu(menu)
    }
    
    private func showStatusItemMenu(_ menu: NSMenu) {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    private func addItem(_ title: String, action: Selector?, key: String, to menu: NSMenu) {
        let item = NSMenuItem()
        item.title = title
        item.target = self
        item.action = action
        item.keyEquivalent = key
        menu.addItem(item)
    }
    
    // MARK: - Actions
    
    @objc
    func showAbout() {
        AboutWindow.show()
    }
    
    @objc
    func quit() {
        NSApp.terminate(self)
    }

    @objc
    func showApp() {
        NSApp.activate(ignoringOtherApps: true)
        // Focus main window if exists
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc
    func addPromise() {
        showApp()
        // TODO: Focus the add promise input field
        // This would require communication with the SwiftUI views
    }
    
    @objc
    func takeScreenshot() {
        Task { @MainActor in
            await AutoPromiseManager.shared.processManualScreenshot()
        }
    }
    
    @objc
    func showMCPStatus() {
        Task { @MainActor in
            let mcpClient = MCPClient.shared
            print("MCP Status - Connected: \(mcpClient.isConnected)")
            if let error = mcpClient.errorMessage {
                print("MCP Error: \(error)")
            }
        }
    }
}

