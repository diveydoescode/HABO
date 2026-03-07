// MARK: - CryptoService.swift
import Foundation
import CryptoKit

@MainActor
class CryptoService {
    static let shared = CryptoService()
    private init() {}

    private let privateKeyTag = "app.habo.nacl.privatekey"

    // MARK: - Key Pair Management
    func getOrCreateKeyPair() throws -> (publicKeyB64: String, privateKeyB64: String) {
        // ✅ 1. Safely load existing key from UserDefaults instead of volatile Keychain
        if let privB64 = UserDefaults.standard.string(forKey: privateKeyTag),
           let privData = Data(base64Encoded: privB64) {
            do {
                let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privData)
                let pubB64 = privateKey.publicKey.rawRepresentation.base64EncodedString()
                return (pubB64, privB64)
            } catch {
                print("Key corrupted, generating new one.")
            }
        }
        
        // ✅ 2. Generate new Curve25519 key pair if one doesn't exist
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let privB64 = privateKey.rawRepresentation.base64EncodedString()
        let pubB64 = privateKey.publicKey.rawRepresentation.base64EncodedString()
        
        // ✅ 3. Save persistently to UserDefaults
        UserDefaults.standard.set(privB64, forKey: privateKeyTag)
        
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

        let combinedB64 = sealedBox.combined.base64EncodedString()
        let nonceB64 = sealedBox.nonce.withUnsafeBytes { Data($0) }.base64EncodedString()

        return (combinedB64, nonceB64)
    }

    // MARK: - Decrypt (recipient decrypts)
    func decrypt(ciphertextB64: String, nonceB64: String, senderPublicKeyB64: String) throws -> String {
        guard let combinedData = Data(base64Encoded: ciphertextB64) else {
            throw CryptoError.invalidBase64
        }
        guard let senderKeyData = Data(base64Encoded: senderPublicKeyB64) else {
            throw CryptoError.invalidKey
        }
        guard let (_, myPrivB64) = try? getOrCreateKeyPair(),
              let myPrivData = Data(base64Encoded: myPrivB64) else {
            throw CryptoError.invalidKey
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

        let sealedBox = try ChaChaPoly.SealedBox(combined: combinedData)
        let plainData = try ChaChaPoly.open(sealedBox, using: symmetricKey)
        
        guard let resultString = String(data: plainData, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        return resultString
    }

    enum CryptoError: Error {
        case invalidKey
        case encryptionFailed
        case decryptionFailed
        case invalidBase64
    }
}
