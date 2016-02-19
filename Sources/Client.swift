import StreamKit

public protocol Client {
    var port: UInt16 { get }
    var host: String { get }
    
    init(host: String, port: UInt16) throws
    
    func connect() throws -> Connection
}