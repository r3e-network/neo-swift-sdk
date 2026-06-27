
import BigInt
import Foundation

public final class BinaryReader {
    
    public var position: Int = 0
    public var available: Int {
        return max(0, array.count - position)
    }
    
    private let array: Bytes
    private var marker: Int = -1
    
    public init(_ input: Bytes) {
        array = input
    }
    
    public func mark() {
        marker = position
    }
    
    public func reset() {
        if marker >= 0 {
            position = marker
        }
    }
    
    public func readBoolean() throws -> Bool {
        return try readByte() == 1
    }
    
    public func readByte() throws -> Byte {
        return try readBytes(1)[0]
    }
    
    public func readUnsignedByte() throws -> Int {
        return try Int(readByte())
    }
    
    public func readBytes(_ length: Int) throws -> Bytes {
        guard length >= 0 else {
            throw NeoError.deserialization("Cannot read a negative number of bytes.")
        }
        guard available >= length else {
            throw NeoError.deserialization("Cannot read \(length) byte\(length == 1 ? "" : "s") at position \(position). Only \(available) byte\(available == 1 ? "" : "s") available.")
        }
        let p = position
        position += length
        return Bytes(array[p..<(p + length)])
    }
    
    public func readUInt16() throws -> UInt16 {
        return try readBytes(2).toNumeric()
    }
    
    public func readInt16() throws -> Int16 {
        return try readBytes(2).toNumeric()
    }
    
    public func readUInt32() throws -> UInt32 {
        return try readBytes(4).toNumeric()
    }
    
    public func readInt32() throws -> Int32 {
        return try readBytes(4).toNumeric()
    }
    
    public func readInt64() throws -> Int64 {
        return try readBytes(8).toNumeric()
    }

    public func readUInt64() throws -> UInt64 {
        return try readBytes(8).toNumeric()
    }
    
    public func readEncodedECPoint() throws -> Bytes {
        let byte = try readByte()
        if byte == 0x02 || byte == 0x03 {
            return try byte + readBytes(32)
        }
        throw NeoError.deserialization("Failed parsing encoded EC point.")
    }
    
    public func readECPoint() throws -> ECPoint {
        let encoded: Bytes
        let byte = try readByte()
        switch byte {
        case 0x00: encoded = [0x00]
        case 0x02, 0x03: encoded = try byte + readBytes(32)
        case 0x04: encoded = try byte + readBytes(64)
        default: throw NeoError.deserialization()
        }
        return try NeoConstants.SECP256R1_DOMAIN.decodePoint(encoded)
    }
    
    public func readSerializable<T: NeoSerializable>() throws -> T {
        return try T.deserialize(self)
    }
    
    public func readSerializableListVarBytes<T: NeoSerializable>() throws -> [T] {
        let length = try readVarInt(0x10000000)
        var bytesRead = 0, offset = position
        var list: [T] = []
        while bytesRead < length {
            do {
                let t = try T.deserialize(self)
                list.append(t)
            } catch {
                throw NeoError.deserialization("Failed to deserialize element at position \(position): \(error.localizedDescription)")
            }
            bytesRead = position - offset
        }
        return list
    }
    
    public func readSerializableList<T: NeoSerializable>() throws -> [T] {
        let length = try readVarInt(0x10000000)
        var list: [T] = []
        for _ in 0..<length {
            do {
                let t = try T.deserialize(self)
                list.append(t)
            } catch {
                throw NeoError.deserialization("Failed to deserialize element at position \(position): \(error.localizedDescription)")
            }
        }
        return list
    }
    
    public func readVarBytes() throws -> Bytes {
        return try readVarBytes(0x1000000)
    }
    
    public func readVarString() throws -> String {
        guard let string = try String(bytes: readVarBytes(), encoding: .utf8) else {
            throw NeoError.deserialization("Failed reading var String.")
        }
        return string
    }
    
    public func readPushData() throws -> Bytes {
        let byte = try readByte()
        let size: Int
        switch byte {
        case OpCode.pushData1.opcode: size = try readUnsignedByte()
        case OpCode.pushData2.opcode: size = try Int(readInt16())
        case OpCode.pushData4.opcode: size = try Int(readInt32())
        default: throw NeoError.deserialization("Stream did not contain a PUSHDATA OpCode at the current position.")
        }
        return try readBytes(size)
    }
    
    public func readVarBytes(_ max: Int) throws -> Bytes {
        let length = try readVarInt(max)
        return try readBytes(length)
    }
    
    public func readVarInt() throws -> Int {
        return try readVarInt(Int.max)
    }
    
    public func readVarInt(_ max: Int) throws -> Int {
        guard max >= 0 else {
            throw NeoError.deserialization("Variable integer maximum must not be negative.")
        }
        let first = try readUnsignedByte()
        let value: Int
        switch first {
        case 0xFD: value = try Int(readUInt16())
        case 0xFE: value = try Int(readUInt32())
        case 0xFF:
            let uint64 = try readUInt64()
            guard uint64 <= UInt64(Int.max) else {
                throw NeoError.deserialization("Variable integer \(uint64) exceeds maximum \(Int.max).")
            }
            value = Int(uint64)
        default: value = Int(first)
        }
        guard value <= max else {
            throw NeoError.deserialization("Variable integer \(value) exceeds maximum \(max).")
        }
        return value
    }
    
    public func readPushString() throws -> String {
        guard let string = try String(bytes: readPushData(), encoding: .utf8) else {
            throw NeoError.deserialization("Couldn't parse PUSHINT OpCode")
        }
        return string
    }
    
    public func readPushInt() throws -> Int {
        guard let int = try readPushBigInt().asInt() else {
            throw NeoError.deserialization("Couldn't parse PUSHINT OpCode")
        }
        return int
    }
    
    public func readPushBigInt() throws -> BInt {
        let byte = try readByte()
        if byte.isBetween(.pushM1, .push16) {
            return BInt(Int(byte) - Int(OpCode.push0.opcode))
        }
        var count = -1
        switch OpCode(rawValue: byte) {
        case .pushInt8: count = 1
        case .pushInt16: count = 2
        case .pushInt32: count = 4
        case .pushInt64: count = 8
        case .pushInt128: count = 16
        case .pushInt256: count = 32
        default: throw NeoError.deserialization("Couldn't parse PUSHINT OpCode")
        }
        return try BInt(signed: readBytes(count))
    }
    
}
