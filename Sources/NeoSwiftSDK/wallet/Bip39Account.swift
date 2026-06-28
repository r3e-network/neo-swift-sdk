import CryptoSwift
import Foundation

/// Class encapsulating a BIP-39 compatible NEO account.
public class Bip39Account: Account {
    
    private let mnemonicBytes: SecureBytes
    
    private init(_ keyPair: SecureECKeyPair, _ mnemonic: String) throws {
        self.mnemonicBytes = SecureBytes(Bytes(mnemonic.utf8))
        try super.init(secureKeyPair: keyPair)
    }

    /// Exports the BIP-39 recovery phrase.
    ///
    /// Treat the returned string as secret material. The SDK keeps the stored phrase in secure memory, but exporting it
    /// necessarily creates an ordinary Swift `String` for the caller to display, back up, or pass to recovery flows.
    public func exportMnemonic() throws -> String {
        var bytes = try mnemonicBytes.toArray()
        defer { bytes.zeroize() }
        guard let mnemonic = String(bytes: bytes, encoding: .utf8) else {
            throw NeoError.illegalState("Stored BIP-39 mnemonic is not valid UTF-8.")
        }
        return mnemonic
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
        var seed = try seed(from: normalizedMnemonic, passphrase: password)
        defer { seed.zeroize() }
        var privateKey = seed.sha256()
        defer { privateKey.zeroize() }
        let keyPair = try SecureECKeyPair.create(privateKey: privateKey)
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
        var password = Bytes(normalize(mnemonic).utf8)
        var salt = Bytes(normalize("mnemonic" + passphrase).utf8)
        defer {
            password.zeroize()
            salt.zeroize()
        }
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

private extension Array where Element == UInt8 {

    mutating func zeroize() {
        guard !isEmpty else { return }
        withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            memset(baseAddress, 0, buffer.count)
        }
    }

}
