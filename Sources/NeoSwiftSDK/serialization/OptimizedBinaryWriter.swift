import Foundation

/// An optimized binary writer that uses pre-allocated buffers to avoid O(n) array reallocations
public class OptimizedBinaryWriter {
    
    private var buffer: UnsafeMutablePointer<UInt8>
    private var capacity: Int
    private var position: Int = 0
    private let growthFactor: Double = 1.5
    private let initialCapacity: Int
    
    public init(initialCapacity: Int = 1024) {
        self.initialCapacity = initialCapacity
        self.capacity = initialCapacity
        self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
    }
    
    deinit {
        buffer.deallocate()
    }
    
    public var size: Int {
        return position
    }
    
    private func ensureCapacity(_ additionalBytes: Int) {
        let requiredCapacity = position + additionalBytes
        guard requiredCapacity > capacity else { return }
        
        // Calculate new capacity with growth factor
        var newCapacity = Int(Double(capacity) * growthFactor)
        while newCapacity < requiredCapacity {
            newCapacity = Int(Double(newCapacity) * growthFactor)
        }
        
        // Allocate new buffer and copy existing data
        let newBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: newCapacity)
        newBuffer.initialize(from: buffer, count: position)
        buffer.deallocate()
        
        buffer = newBuffer
        capacity = newCapacity
    }
    
    public func write(_ bytes: Bytes) {
        ensureCapacity(bytes.count)
        guard !bytes.isEmpty else { return }
        bytes.withUnsafeBytes { src in
            if let baseAddress = src.bindMemory(to: UInt8.self).baseAddress {
                buffer.advanced(by: position).initialize(from: baseAddress, count: bytes.count)
            }
        }
        position += bytes.count
    }
    
    public func writeBoolean(_ v: Bool) {
        writeByte(v ? 1 : 0)
    }
    
    public func writeByte(_ v: Byte) {
        ensureCapacity(1)
        buffer[position] = v
        position += 1
    }
    
    public func writeDouble(_ v: Double) {
        write(v.bigEndianBytes)
    }
    
    public func writeECPoint(_ v: ECPoint) throws {
        write(try v.getEncoded(true))
    }
    
    public func writeFixedString(_ v: String?, length: Int) throws {
        guard let bytes = v?.bytes, bytes.count <= length else {
            throw NeoError.illegalArgument("String to write is longer than specified length")
        }
        write(try bytes.toPadded(length: length, trailing: true))
    }
    
    public func writeFloat(_ v: Float) {
        write(v.bigEndianBytes)
    }
    
    public func writeInt32(_ v: Int32) {
        write(v.bigEndianBytes)
    }
    
    public func writeInt64(_ v: Int64) {
        write(v.bigEndianBytes)
    }
    
    public func writeUInt32(_ v: UInt32) {
        write(v.bigEndianBytes)
    }
    
    public func writeSerializableVariableBytes(_ v: NeoSerializable) {
        let tempWriter = BinaryWriter()
        v.serialize(tempWriter)
        let bytes = tempWriter.toArray()
        writeVarInt(bytes.count)
        write(bytes)
    }
    
    public func writeSerializableVariable(_ v: [NeoSerializable]) {
        writeVarInt(v.count)
        writeSerializableFixed(v)
    }
    
    public func writeSerializableVariableBytes(_ v: [NeoSerializable]) {
        writeVarInt(v.reduce(0) { $0 + $1.toArray().count })
        writeSerializableFixed(v)
    }
    
    public func writeSerializableFixed(_ v: NeoSerializable) {
        let tempWriter = BinaryWriter()
        v.serialize(tempWriter)
        write(tempWriter.toArray())
    }
    
    public func writeSerializableFixed(_ v: [NeoSerializable]) {
        v.forEach { value in
            writeSerializableFixed(value)
        }
    }
    
    public func writeUInt16(_ v: UInt16) {
        write(v.bigEndianBytes)
    }
    
    public func writeVarBytes(_ v: Bytes) {
        writeVarInt(v.count)
        write(v)
    }
    
    public func writeVarInt(_ v: Int) {
        guard v >= 0 else {
            return
        }
        if (v < 0xFD) {
            writeByte(Byte(v))
        } else if (v <= 0xFFFF) {
            writeByte(0xFD)
            writeUInt16(UInt16(v))
        } else if (v <= 0xFFFFFFFF) {
            writeByte(0xFE)
            writeUInt32(UInt32(v))
        } else {
            writeByte(0xFF)
            writeInt64(Int64(v))
        }
    }
    
    public func writeVarString(_ v: String) {
        writeVarBytes(v.bytes)
    }
    
    public func reset() {
        position = 0
    }
    
    public func toArray() -> Bytes {
        let result = Array(UnsafeBufferPointer(start: buffer, count: position))
        reset()
        return result
    }
}

/// Extension to make OptimizedBinaryWriter compatible with BinaryWriter interface
extension BinaryWriter {
    /// Create an optimized version of this writer
    public static func optimized(initialCapacity: Int = 1024) -> BinaryWriter {
        return OptimizedBinaryWriterAdapter(initialCapacity: initialCapacity)
    }
}

/// Adapter class to make OptimizedBinaryWriter work with existing BinaryWriter interface
private class OptimizedBinaryWriterAdapter: BinaryWriter {
    private let optimizedWriter: OptimizedBinaryWriter
    
    init(initialCapacity: Int = 1024) {
        self.optimizedWriter = OptimizedBinaryWriter(initialCapacity: initialCapacity)
        super.init()
    }
    
    override var size: Int {
        return optimizedWriter.size
    }
    
    override func write(_ buffer: Bytes) {
        optimizedWriter.write(buffer)
    }
    
    override func writeBoolean(_ v: Bool) {
        optimizedWriter.writeBoolean(v)
    }
    
    override func writeByte(_ v: Byte) {
        optimizedWriter.writeByte(v)
    }
    
    override func writeDouble(_ v: Double) {
        optimizedWriter.writeDouble(v)
    }
    
    override func writeECPoint(_ v: ECPoint) throws {
        try optimizedWriter.writeECPoint(v)
    }
    
    override func writeFixedString(_ v: String?, length: Int) throws {
        try optimizedWriter.writeFixedString(v, length: length)
    }
    
    override func writeFloat(_ v: Float) {
        optimizedWriter.writeFloat(v)
    }
    
    override func writeInt32(_ v: Int32) {
        optimizedWriter.writeInt32(v)
    }
    
    override func writeInt64(_ v: Int64) {
        optimizedWriter.writeInt64(v)
    }
    
    override func writeUInt32(_ v: UInt32) {
        optimizedWriter.writeUInt32(v)
    }
    
    override func writeUInt16(_ v: UInt16) {
        optimizedWriter.writeUInt16(v)
    }
    
    override func writeVarBytes(_ v: Bytes) {
        optimizedWriter.writeVarBytes(v)
    }
    
    override func writeVarInt(_ v: Int) {
        optimizedWriter.writeVarInt(v)
    }
    
    override func writeVarString(_ v: String) {
        optimizedWriter.writeVarString(v)
    }
    
    override func reset() {
        optimizedWriter.reset()
    }
    
    override func toArray() -> Bytes {
        return optimizedWriter.toArray()
    }
}
