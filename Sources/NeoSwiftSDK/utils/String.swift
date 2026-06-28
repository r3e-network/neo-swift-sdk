
import Foundation

public extension String {
    
    var bytesFromHex: Bytes {
        return Bytes(hex: cleanedHexPrefix)
    }
    
    var cleanedHexPrefix: String {
        return starts(with: "0x") ? String(dropFirst(2)) : self
    }
    
    var base64Decoded: Bytes {
        guard let data = Data(base64Encoded: self) else { return [] }
        return [UInt8](data)
    }
    
    var base64Encoded: String {
        return bytesFromHex.base64Encoded
    }
    
    var base58Decoded: Bytes? {
        return Base58.decode(self)
    }
    
    var base58CheckDecoded: Bytes? {
        return Base58.base58CheckDecode(self)
    }
    
    var base58Encoded: String {
        return bytes.base58Encoded
    }
    
    var varSize: Int {
        bytes.varSize
    }
    
    var isValidAddress: Bool {
        isValidAddress(addressVersion: NeoRpcClientConfiguration.addressVersion)
    }

    func isValidAddress(addressVersion: Byte) -> Bool {
        guard let data = base58Decoded, data.count == 25,
              data[0] == addressVersion,
              Bytes(data.prefix(21)).hash256().prefix(4) == data.suffix(4) else {
            return false
        }
        return true
    }
    
    var isValidHex: Bool {
        let hex = cleanedHexPrefix
        return hex.count == hex.filter(\.isHexDigit).count && hex.count % 2 == 0
    }

    func bytesFromValidatedHex(_ fieldName: String, allowEmpty: Bool = false) throws -> Bytes {
        let hex = cleanedHexPrefix
        guard allowEmpty || !hex.isEmpty else {
            throw NeoError.illegalArgument("\(fieldName) must not be empty.")
        }
        guard isValidHex else {
            throw NeoError.illegalArgument("\(fieldName) must be an even-length hexadecimal string.")
        }
        return Bytes(hex: hex)
    }
    
    func addressToScriptHash() throws -> Bytes {
        try addressToScriptHash(addressVersion: NeoRpcClientConfiguration.addressVersion)
    }

    func addressToScriptHash(addressVersion: Byte) throws -> Bytes {
        guard isValidAddress(addressVersion: addressVersion), let b58 = base58Decoded else {
            throw NeoError.illegalArgument("Not a valid NEO address.")
        }
        return b58[1..<21].reversed()
    }
    
    var reversedHex: String {
        return Bytes(bytesFromHex.reversed()).noPrefixHex
    }
    
}
