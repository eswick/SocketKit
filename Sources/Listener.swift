public protocol Listener {
    var port: Int32 { get }
    
    init(port: Int32) throws
    
    func accept() throws -> Connection
    func close() throws
}