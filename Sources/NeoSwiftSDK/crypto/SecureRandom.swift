import Foundation

#if canImport(Security)
import Security
#endif

enum SecureRandom {

    static func bytes(count: Int) throws -> Bytes {
        guard count >= 0 else {
            throw NeoError.illegalArgument("Random byte count must not be negative.")
        }
        guard count > 0 else { return [] }

        var output = Bytes(repeating: 0, count: count)

        #if canImport(Security)
        let status = output.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, count, buffer.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw NeoError.runtime("Unable to read secure random bytes.")
        }
        return output
        #elseif os(Linux)
        let file = try FileHandle(forReadingFrom: URL(fileURLWithPath: "/dev/urandom"))
        defer { try? file.close() }
        let data = file.readData(ofLength: count)
        guard data.count == count else {
            throw NeoError.runtime("Unable to read enough secure random bytes.")
        }
        return Bytes(data)
        #else
        throw NeoError.unsupportedOperation("Secure random bytes are not available on this platform.")
        #endif
    }

}
