
import CryptoSwift
import Foundation
import Scrypt

/// Provides encryption and decryption functionality according to NEP-2 specification.
public class NEP2 {
    
    public static let DKLEN: Int = 64
    public static let NEP2_PRIVATE_KEY_LENGTH: Int = 39
    public static let NEP2_PREFIX_1: Byte = 0x01
    public static let NEP2_PREFIX_2: Byte = 0x42
    public static let NEP2_FLAGBYTE: Byte = 0xE0
    
    /// Decrypts the given encrypted private key in NEP-2 format with the given password and standard scrypt parameters.
    /// - Parameters:
    ///   - password: The passphrase used for decryption
    ///   - nep2String: The NEP-2 encrypted private key
    ///   - params: The scrypt parameters used for encryption
    /// - Returns: An EC key pair constructed form the decrypted private key
    @available(*, deprecated, message: "Use decryptSecure(_:_:_:) to avoid exporting private key bytes into ordinary memory.")
    public static func decrypt(_ password: String, _ nep2String: String, _ params: ScryptParams = .DEFAULT) throws -> ECKeyPair {
        try decryptSecure(password, nep2String, params).toLegacyKeyPair()
    }

    /// Decrypts the given encrypted private key in NEP-2 format into secure key storage.
    /// - Parameters:
    ///   - password: The passphrase used for decryption
    ///   - nep2String: The NEP-2 encrypted private key
    ///   - params: The scrypt parameters used for encryption
    /// - Returns: A secure EC key pair constructed from the decrypted private key
    public static func decryptSecure(_ password: String, _ nep2String: String, _ params: ScryptParams = .DEFAULT) throws -> SecureECKeyPair {
        guard let nep2Data = nep2String.base58CheckDecoded, nep2Data.count == NEP2_PRIVATE_KEY_LENGTH,
              nep2Data[0] == NEP2_PREFIX_1, nep2Data[1] == NEP2_PREFIX_2, nep2Data[2] == NEP2_FLAGBYTE else {
            throw NEP2Error.invalidFormat("Not valid NEP2 prefix.")
        }
        let addressHash = Bytes(nep2Data[3..<7]), encrypted = Bytes(nep2Data[7..<39])
        let derivedKey = try generateDerivedScryptKey(password.bytes, addressHash, params)
        var decryptedBytes = try performCipher(encrypted, Bytes(derivedKey.suffix(32)), decrypt: true)
        var plainPrivateKey = try Bytes(derivedKey.prefix(32)) ^ decryptedBytes
        defer {
            decryptedBytes.zeroize()
            plainPrivateKey.zeroize()
        }
        let keyPair = try SecureECKeyPair.create(privateKey: plainPrivateKey)
        let newAddressHash = try getAddressHash(keyPair)
        guard ConstantTime.areEqual(newAddressHash, addressHash) else {
            throw NEP2Error.invalidPassphrase("Calculated address hash does not match the one in the provided encrypted address.")
        }
        return keyPair
    }
    
    /// Encrypts the private key of the given EC key pair following the NEP-2 standard.
    /// - Parameters:
    ///   - password: The passphrase to be used to encrypt
    ///   - ecKeyPair: The ``ECKeyPair`` to be encrypted
    ///   - n: The "n" parameter for ``ScryptParams/init(_:_:_:)``
    ///   - r: The "r" parameter for ``ScryptParams/init(_:_:_:)``
    ///   - p: The "p" parameter for ``ScryptParams/init(_:_:_:)``
    /// - Returns: The NEP-2 encrypted private key
    public static func encrypt(_ password: String, _ ecKeyPair: ECKeyPair, _ n: Int, _ r: Int, _ p: Int) throws -> String {
        return try encrypt(password, ecKeyPair, .init(n, r, p))
    }
    
    /// Encrypts the private key of the given EC key pair following the NEP-2 standard.
    /// - Parameters:
    ///   - password: The passphrase to be used to encrypt
    ///   - ecKeyPair: The ``ECKeyPair`` to be encrypted
    ///   - params: The scrypt parameters used for encryption
    /// - Returns: The NEP-2 encrypted private key
    public static func encrypt(_ password: String, _ ecKeyPair: ECKeyPair, _ params: ScryptParams = .DEFAULT) throws -> String {
        try encrypt(password, privateKey: ecKeyPair.privateKey.bytes, addressHash: getAddressHash(ecKeyPair), params)
    }

    private static func encrypt(_ password: String, privateKey: Bytes, addressHash: Bytes, _ params: ScryptParams) throws -> String {
        let derivedKey = try generateDerivedScryptKey(password.bytes, addressHash, params)
        let derivedHalf1 = Bytes(derivedKey.prefix(32)), derivedHalf2 = Bytes(derivedKey.suffix(32))
        let encryptedHalf1 = try performCipher(xorPrivateKeyAndDerivedHalf(privateKey, derivedHalf1, 0..<16),
                                               derivedHalf2, decrypt: false)
        let encryptedHalf2 = try performCipher(xorPrivateKeyAndDerivedHalf(privateKey, derivedHalf1, 16..<32),
                                               derivedHalf2, decrypt: false)
        return ([NEP2_PREFIX_1, NEP2_PREFIX_2, NEP2_FLAGBYTE] + addressHash + encryptedHalf1 + encryptedHalf2).base58CheckEncoded
    }

    /// Encrypts the private key of the given secure EC key pair following the NEP-2 standard.
    /// - Parameters:
    ///   - password: The passphrase to be used to encrypt
    ///   - ecKeyPair: The secure key pair to be encrypted
    ///   - params: The scrypt parameters used for encryption
    /// - Returns: The NEP-2 encrypted private key
    public static func encrypt(_ password: String, _ ecKeyPair: SecureECKeyPair, _ params: ScryptParams = .DEFAULT) throws -> String {
        try ecKeyPair.withPrivateKeyBytes {
            try encrypt(password, privateKey: $0, addressHash: getAddressHash(ecKeyPair), params)
        }
    }
    
    private static func xorPrivateKeyAndDerivedHalf(_ privateKey: Bytes, _ half: Bytes, _ range: Range<Int>) throws -> Bytes {
        return try Bytes(privateKey[range]) ^ Bytes(half[range])
    }
    
    private static func performCipher(_ data: Bytes, _ key: Bytes, decrypt: Bool) throws -> Bytes {
        let aes = try AES(key: key, blockMode: ECB(), padding: .noPadding)
        return try decrypt ? aes.decrypt(data) : aes.encrypt(data)
    }
    
    private static func generateDerivedScryptKey(_ password: Bytes, _ salt: Bytes, _ scryptParams: ScryptParams) throws -> Bytes {
        return try scrypt(password: password,
                          salt: salt, length: DKLEN,
                          N: UInt64(scryptParams.n),
                          r: UInt32(scryptParams.r),
                          p: UInt32(scryptParams.p))
    }
    
    private static func getAddressHash(_ keyPair: ECKeyPair) throws -> Bytes {
        return try .init(keyPair.getAddress().hash256().bytesFromHex.prefix(4))
    }

    private static func getAddressHash(_ keyPair: SecureECKeyPair) throws -> Bytes {
        return try .init(keyPair.getAddress().hash256().bytesFromHex.prefix(4))
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
