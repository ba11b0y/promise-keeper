#!/usr/bin/env swift

import Foundation
import CryptoKit

guard CommandLine.arguments.count == 3 else {
    print("Usage: swift sign_release.swift <private_key_base64> <file_path>")
    print("Example: swift sign_release.swift 'pBCGm80E...' '/path/to/YourApp.dmg'")
    exit(1)
}

let privateKeyBase64 = CommandLine.arguments[1]
let filePath = CommandLine.arguments[2]

// Decode private key
guard let privateKeyData = Data(base64Encoded: privateKeyBase64) else {
    print("Error: Invalid private key format")
    exit(1)
}

// Load file data
guard let fileData = FileManager.default.contents(atPath: filePath) else {
    print("Error: Could not read file at \(filePath)")
    exit(1)
}

do {
    // Create private key
    let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
    
    // Sign the file
    let signature = try privateKey.signature(for: fileData)
    let signatureBase64 = signature.base64EncodedString()
    
    print("File: \(filePath)")
    print("Size: \(fileData.count) bytes")
    print("Signature: \(signatureBase64)")
    print("")
    print("Add this to your appcast.xml:")
    print("sparkle:edSignature=\"\(signatureBase64)\"")
    
} catch {
    print("Error signing file: \(error)")
    exit(1)
}