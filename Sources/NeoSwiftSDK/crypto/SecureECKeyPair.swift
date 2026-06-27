import BigInt
import Foundation
import SwiftECC

/// A secure version of ECKeyPair that uses SecureBytes for private key storage
public class SecureECKeyPair {
    
    /// The private key stored securely
    private let securePrivateKey: SecureBytes
    
    /// The public key of this EC key pair
    public let publicKey: ECPublicKey
    
    /// The underlying ECPrivateKey (created on demand and cleared after use)
    private var _privateKey: ECPrivateKey?
    
    private init(securePrivateKey: SecureBytes, publicKey: ECPublicKey) {
        self.securePrivateKey = securePrivateKey
        self.publicKey = publicKey
    }
    
    /// Access the private key temporarily for operations
    private func withPrivateKey<Result>(_ body: (ECPrivateKey) throws -> Result) rethrows -> Result {
        let privateKey = try! ECPrivateKey(securePrivateKey.toArray())
        defer {
            // Clear any temporary data
            _privateKey = nil
        }
        return try body(privateKey)
    }
    
    /// Constructs the NEO address from this key pair's public key.
    public func getAddress() throws -> String {
        return try getScriptHash().toAddress()
    }
    
    /// Constructs the script hash from this key pairs public key.
    public func getScriptHash() throws -> Hash160 {
        let script = try ScriptBuilder.buildVerificationScript(publicKey.getEncoded(compressed: true))
        return try Hash160.fromScript(script)
    }
    
    /// Sign a hash with the private key of this key pair.
    public func sign(messageHash: Bytes) -> [BInt] {
        let signature: ECDSASignature = signAndGetECDSASignature(messageHash: messageHash)
        return [signature.r, signature.s]
    }
    
    /// Sign a hash with the private key of this key pair.
    public func signAndGetECDSASignature(messageHash: Bytes) -> ECDSASignature {
        return withPrivateKey { privateKey in
            ECDSASignature(signature: privateKey.sign(msg: messageHash, deterministic: true))
        }
    }
    
    /// Creates a secure EC key pair from a private key.
    public static func create(privateKey: ECPrivateKey) throws -> SecureECKeyPair {
        let securePrivateKey = SecureBytes(privateKey.bytes)
        let publicKey = try Sign.publicKeyFromPrivateKey(privKey: privateKey)
        return SecureECKeyPair(securePrivateKey: securePrivateKey, publicKey: publicKey)
    }
    
    /// Creates a secure EC key pair from private key bytes.
    public static func create(privateKey: Bytes) throws -> SecureECKeyPair {
        let ecPrivateKey = try ECPrivateKey(privateKey)
        return try create(privateKey: ecPrivateKey)
    }
    
    /// Create a fresh secure secp256r1 EC key pair.
    public static func createEcKeyPair() throws -> SecureECKeyPair {
        let (pub, priv) = NeoConstants.SECP256R1_DOMAIN.makeKeyPair()
        let securePrivateKey = SecureBytes(priv.bytes)
        return SecureECKeyPair(securePrivateKey: securePrivateKey, publicKey: pub)
    }
    
    /// Export as WIF (creates temporary private key)
    public func exportAsWif() throws -> String {
        return try withPrivateKey { privateKey in
            try privateKey.bytes.wifFromPrivateKey()
        }
    }
    
    /// Create a legacy ECKeyPair (use only when absolutely necessary)
    public func toLegacyKeyPair() throws -> ECKeyPair {
        return withPrivateKey { privateKey in
            ECKeyPair(privateKey: privateKey, publicKey: publicKey)
        }
    }
}

/// Extension to provide migration path from ECKeyPair to SecureECKeyPair
extension ECKeyPair {
    /// Convert to secure key pair (original private key data remains in memory)
    public func toSecureKeyPair() -> SecureECKeyPair {
        return try! SecureECKeyPair.create(privateKey: self.privateKey)
    }
}