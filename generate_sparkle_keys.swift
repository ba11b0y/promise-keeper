#!/usr/bin/env swift

import Foundation
import CryptoKit

// Generate ED25519 key pair for Sparkle
let privateKey = Curve25519.Signing.PrivateKey()
let publicKey = privateKey.publicKey

// Convert to base64 strings
let privateKeyData = privateKey.rawRepresentation
let publicKeyData = publicKey.rawRepresentation

let privateKeyBase64 = privateKeyData.base64EncodedString()
let publicKeyBase64 = publicKeyData.base64EncodedString()

print("=== Sparkle Signing Keys ===")
print("")
print("Private Key (keep this SECRET):")
print(privateKeyBase64)
print("")
print("Public Key (add to Info.plist):")
print(publicKeyBase64)
print("")
print("=== Next Steps ===")
print("1. Save the private key in a secure location (you'll need it to sign releases)")
print("2. Update Info.plist with the public key")
print("3. Never share or commit the private key!")