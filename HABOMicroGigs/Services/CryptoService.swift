// MARK: - CryptoService.swift
import Foundation
import CryptoKit
import Security

@MainActor
class CryptoService {
    static let shared = CryptoService()
    private init() {}

    private let privateKeyTag = "app.habo.nacl.privatekey"

    // MARK: - Key Pair Management
    func getOrCreateKeyPair() throws -> (publicKeyB64: String, privateKeyB64: String) {
        if let existing = loadPrivateKey() {
            let pubB64 = existing.publicKey.rawRepresentation.base64EncodedString()
            let privB64 = existing.rawRepresentation.base64EncodedString()
            return (pubB64, privB64)
        }
        
        // Generate new Curve25519 key pair
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        try savePrivateKey(privateKey)
        
        let pubB64 = privateKey.publicKey.rawRepresentation.base64EncodedString()
        let privB64 = privateKey.rawRepresentation.base64EncodedString()
        return (pubB64, privB64)
    }

    func getPublicKeyB64() throws -> String {
        let (pub, _) = try getOrCreateKeyPair()
        return pub
    }

    // MARK: - Encrypt (sender encrypts for recipient)
    func encrypt(plaintext: String, recipientPublicKeyB64: String) throws -> (ciphertext: String, nonce: String) {
        guard let recipientKeyData = Data(base64Encoded: recipientPublicKeyB64),
              let (_, senderPrivB64) = try? getOrCreateKeyPair(),
              let senderPrivData = Data(base64Encoded: senderPrivB64) else {
            throw CryptoError.invalidKey
        }

        let recipientPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientKeyData)
        let senderPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: senderPrivData)

        // Perform ECDH key agreement
        let sharedSecret = try senderPrivateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)

        // Derive symmetric key using HKDF
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("habo-e2ee-salt".utf8),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        // Encrypt with ChaCha20-Poly1305
        let plaintextData = Data(plaintext.utf8)
        let sealedBox = try ChaChaPoly.seal(plaintextData, using: symmetricKey)

        // ✅ FIX: Use CryptoKit's native `.combined` to keep nonce, ciphertext, and tag safely together
        let combinedB64 = sealedBox.combined.base64EncodedString()
        let nonceB64 = sealedBox.nonce.withUnsafeBytes { Data($0) }.base64EncodedString()

        // We send the combined data as the 'ciphertext' field so the tag is never lost
        return (combinedB64, nonceB64)
    }

    // MARK: - Decrypt (recipient decrypts)
    func decrypt(ciphertextB64: String, nonceB64: String, senderPublicKeyB64: String) throws -> String {
        // ✅ FIX: We expect `ciphertextB64` to be the full `combined` payload
        guard let combinedData = Data(base64Encoded: ciphertextB64),
              let senderKeyData = Data(base64Encoded: senderPublicKeyB64),
              let (_, myPrivB64) = try? getOrCreateKeyPair(),
              let myPrivData = Data(base64Encoded: myPrivB64) else {
            throw CryptoError.decryptionFailed
        }

        let senderPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: senderKeyData)
        let myPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: myPrivData)

        let sharedSecret = try myPrivateKey.sharedSecretFromKeyAgreement(with: senderPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("habo-e2ee-salt".utf8),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        // ✅ FIX: Initialize the SealedBox securely using the combined data (prevents Error 1)
        let sealedBox = try ChaChaPoly.SealedBox(combined: combinedData)
        let plainData = try ChaChaPoly.open(sealedBox, using: symmetricKey)
        
        return String(data: plainData, encoding: .utf8) ?? "???"
    }

    // MARK: - Keychain Helpers
    private func savePrivateKey(_ key: Curve25519.KeyAgreement.PrivateKey) throws {
        let keyData = key.rawRepresentation
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: privateKeyTag,
            kSecValueData: keyData,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw CryptoError.keychainError }
    }

    private func loadPrivateKey() -> Curve25519.KeyAgreement.PrivateKey? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: privateKeyTag,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let key = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
        else { return nil }
        return key
    }

    enum CryptoError: Error {
        case invalidKey
        case decryptionFailed
        case keychainError
    }
}
