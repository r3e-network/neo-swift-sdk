import CryptoSwift
import Foundation

/// Class encapsulating a BIP-39 compatible NEO account.
public class Bip39Account: Account {
    
    /// Generated BIP-39 mnemonic for the account.
    public let mnemonic: String
    
    private init(_ keyPair: ECKeyPair, _ mnemonic: String) throws {
        self.mnemonic = mnemonic
        try super.init(keyPair: keyPair)
    }
    
    /// Generates a BIP-39 compatible NEO account. The private key for the wallet can be calculated using following algorithm:\n
    /// `Key = SHA-256(BIP_39_SEED(mnemonic, password))`
    /// The password will *only* be used as passphrase for BIP-39 seed (i.e., used to recover the account).
    /// - Parameter password: The passphrase with which to encrypt the private key
    /// - Returns: A BIP-39 compatible Neo account
    public static func create(_ password: String) throws -> Bip39Account {
        let mnemonic = try mnemonic(fromEntropy: SecureRandom.bytes(count: 16))
        return try fromBip39Mnemonic(password, mnemonic)
    }
    
    /// Recovers a key pair based on BIP-39 mnemonic and password.
    /// - Parameters:
    ///   - password: The passphrase given when the BIP-39 account was generated
    ///   - mnemonic: The generated mnemonic with the given passphrase
    /// - Returns: A Bip39Account builder
    public static func fromBip39Mneumonic(_ password: String, _ mnemonic: String) throws -> Bip39Account {
        try fromBip39Mnemonic(password, mnemonic)
    }

    /// Recovers a key pair based on BIP-39 mnemonic and password.
    /// - Parameters:
    ///   - password: The passphrase given when the BIP-39 account was generated
    ///   - mnemonic: The generated mnemonic with the given passphrase
    /// - Returns: A Bip39Account builder
    public static func fromBip39Mnemonic(_ password: String, _ mnemonic: String) throws -> Bip39Account {
        let normalizedMnemonic = try validatedMnemonic(mnemonic)
        let seed = try seed(from: normalizedMnemonic, passphrase: password)
        let keyPair = try ECKeyPair.create(privateKey: seed.sha256())
        return try .init(keyPair, normalizedMnemonic)
    }
    
}

private extension Bip39Account {

    static let validEntropyByteCounts: Set<Int> = [16, 20, 24, 28, 32]
    static let validMnemonicWordCounts: Set<Int> = [12, 15, 18, 21, 24]

    static func mnemonic(fromEntropy entropy: Bytes) throws -> String {
        guard validEntropyByteCounts.contains(entropy.count) else {
            throw NeoError.illegalArgument("BIP-39 entropy must be 128, 160, 192, 224, or 256 bits.")
        }

        let entropyBitCount = entropy.count * 8
        let checksumBitCount = entropyBitCount / 32
        var mnemonicBits = bits(from: entropy)
        mnemonicBits.append(contentsOf: bits(from: entropy.sha256()).prefix(checksumBitCount))

        let words = try stride(from: 0, to: mnemonicBits.count, by: 11).map { offset in
            let index = mnemonicBits[offset..<(offset + 11)].reduce(0) { ($0 << 1) | ($1 ? 1 : 0) }
            guard BIP39EnglishWordList.words.indices.contains(index) else {
                throw NeoError.illegalState("BIP-39 word index out of range.")
            }
            return BIP39EnglishWordList.words[index]
        }
        return words.joined(separator: " ")
    }

    static func validatedMnemonic(_ mnemonic: String) throws -> String {
        let words = normalize(mnemonic)
            .split(separator: " ")
            .map(String.init)

        guard validMnemonicWordCounts.contains(words.count) else {
            throw NeoError.illegalArgument("BIP-39 mnemonic must contain 12, 15, 18, 21, or 24 words.")
        }

        let indices = try words.map { word -> Int in
            guard let index = BIP39EnglishWordList.indices[word] else {
                throw NeoError.illegalArgument("BIP-39 mnemonic contains an unknown word: \(word).")
            }
            return index
        }

        let allBits = indices.flatMap { index in
            (0..<11).reversed().map { bit in ((index >> bit) & 1) == 1 }
        }
        let entropyBitCount = allBits.count * 32 / 33
        let checksumBitCount = entropyBitCount / 32
        let entropy = try bytes(from: allBits.prefix(entropyBitCount))
        let checksum = Array(allBits.suffix(checksumBitCount))
        let expectedChecksum = Array(bits(from: entropy.sha256()).prefix(checksumBitCount))

        guard checksum == expectedChecksum else {
            throw NeoError.illegalArgument("BIP-39 mnemonic checksum is invalid.")
        }

        return words.joined(separator: " ")
    }

    static func seed(from mnemonic: String, passphrase: String) throws -> Bytes {
        let password = Bytes(normalize(mnemonic).utf8)
        let salt = Bytes(normalize("mnemonic" + passphrase).utf8)
        return try PKCS5.PBKDF2(
            password: password,
            salt: salt,
            iterations: 2048,
            keyLength: 64,
            variant: .sha2(.sha512)
        ).calculate()
    }

    static func bits(from bytes: Bytes) -> [Bool] {
        bytes.flatMap { byte in
            (0..<8).reversed().map { bit in ((byte >> bit) & 1) == 1 }
        }
    }

    static func bytes(from bits: ArraySlice<Bool>) throws -> Bytes {
        guard bits.count % 8 == 0 else {
            throw NeoError.illegalArgument("Bit count must be divisible by 8.")
        }

        var bytes = Bytes()
        bytes.reserveCapacity(bits.count / 8)
        var index = bits.startIndex
        while index < bits.endIndex {
            let nextIndex = bits.index(index, offsetBy: 8)
            let byte = bits[index..<nextIndex].reduce(UInt8(0)) { ($0 << 1) | ($1 ? 1 : 0) }
            bytes.append(byte)
            index = nextIndex
        }
        return bytes
    }

    static func normalize(_ string: String) -> String {
        (string as NSString).decomposedStringWithCompatibilityMapping
    }

}
