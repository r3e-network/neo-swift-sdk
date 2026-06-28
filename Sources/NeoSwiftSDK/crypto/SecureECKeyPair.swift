import BigInt
import Foundation
import SwiftECC

/// A secure version of ECKeyPair that uses SecureBytes for private key storage
public class SecureECKeyPair {
    
    /// The private key stored securely
    private let securePrivateKey: SecureBytes
    
    /// The public key of this EC key pair
    public let publicKey: ECPublicKey
    
    private init(securePrivateKey: SecureBytes, publicKey: ECPublicKey) {
        self.securePrivateKey = securePrivateKey
        self.publicKey = publicKey
    }
    
    /// Access the private key temporarily for operations
    private func withPrivateKey<Result>(_ body: (ECPrivateKey) throws -> Result) throws -> Result {
        var keyBytes = try securePrivateKey.toArray()
        defer { keyBytes.zeroize() }
        let privateKey = try ECPrivateKey(keyBytes)
        return try body(privateKey)
    }

    /// Access a temporary copy of the private key bytes for operations that cannot consume ``SecureBytes`` directly.
    func withPrivateKeyBytes<Result>(_ body: (Bytes) throws -> Result) throws -> Result {
        var keyBytes = try securePrivateKey.toArray()
        defer { keyBytes.zeroize() }
        return try body(keyBytes)
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
    public func sign(messageHash: Bytes) throws -> [BInt] {
        let signature: ECDSASignature = try signAndGetECDSASignature(messageHash: messageHash)
        return [signature.r, signature.s]
    }
    
    /// Sign a hash with the private key of this key pair.
    public func signAndGetECDSASignature(messageHash: Bytes) throws -> ECDSASignature {
        return try withPrivateKey { privateKey in
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
        return try withPrivateKey { privateKey in
            ECKeyPair(privateKey: privateKey, publicKey: publicKey)
        }
    }

    /// Temporarily creates a legacy ``ECKeyPair`` for APIs that have not yet moved to secure key storage.
    public func withLegacyKeyPair<Result>(_ body: (ECKeyPair) throws -> Result) throws -> Result {
        try withPrivateKey { privateKey in
            try body(ECKeyPair(privateKey: privateKey, publicKey: publicKey))
        }
    }
}

private extension Array where Element == UInt8 {

    mutating func zeroize() {
        guard !isEmpty else { return }
        withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            memset(baseAddress, 0, buffer.count)
        }
    }

}

/// Extension to provide migration path from ECKeyPair to SecureECKeyPair
extension ECKeyPair {
    /// Convert to secure key pair (original private key data remains in memory)
    public func toSecureKeyPair() throws -> SecureECKeyPair {
        return try SecureECKeyPair.create(privateKey: self.privateKey)
    }
}
