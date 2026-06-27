
import Foundation

public extension Array {
    
    static func + (lhs: Array<Element>, rhs: Element) -> Array<Element> {
        return lhs + [rhs]
    }
    
    static func + (lhs: Element, rhs: Array<Element>) -> Array<Element> {
        return [lhs] + rhs
    }
    
}

public extension Data {
    
    /// Convert Data to Bytes ([UInt8])
    var bytes: Bytes {
        return [UInt8](self)
    }
    
}
