protocol Listener {
    var port: Int32 { get }
    
    func accept() throws -> Connection
    func close() throws
}