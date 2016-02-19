#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import StreamKit

enum TCPClientError: ErrorType {
    case SocketFailed(Int32)
    case GetAddrInfoFailed(Int32)
    case ConnectFailed(Int32)
}

public class TCPClient: Client {
    public let host: String
    public let port: UInt16
    
    public required init(host: String, port: UInt16) throws {
        self.host = host
        self.port = port
    }
    
    private func htonsPort(port: in_port_t) -> in_port_t {
        #if os(Linux)
            return htons(port)
        #else
            let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
            return isLittleEndian ? _OSSwapInt16(port) : port
        #endif
    }
    
    private func getAddressInfo(address: String) throws -> sockaddr {
        var hint = addrinfo()
        var res = UnsafeMutablePointer<addrinfo>()
        
        memset(&hint, 0, sizeof(addrinfo))
        
        hint.ai_family = AF_INET
        
        let result = getaddrinfo(address, nil, &hint, &res)
        if result != 0 {
            throw TCPClientError.GetAddrInfoFailed(result)
        }
        
        let sock = res.memory.ai_addr.memory
        freeaddrinfo(res)
        
        return sock
    }
    
    public func connect() throws -> Connection {
        var info = try getAddressInfo(host)
        
        if info.sa_family == sa_family_t(AF_INET) {
            withUnsafePointer(&info) { pointer in
                let info4: UnsafeMutablePointer<sockaddr_in> = unsafeBitCast(pointer, UnsafeMutablePointer<sockaddr_in>.self)
                info4.memory.sin_port = self.htonsPort(port)
            }
        } else if info.sa_family == sa_family_t(AF_INET6) {
            withUnsafePointer(&info) { pointer in
                let info6: UnsafeMutablePointer<sockaddr_in6> = unsafeBitCast(pointer, UnsafeMutablePointer<sockaddr_in6>.self)
                info6.memory.sin6_port = self.htonsPort(port)
            }
        }
        
        let sockfd = socket(Int32(info.sa_family), SOCK_STREAM, 0)
        
        if sockfd == -1 {
            throw TCPClientError.SocketFailed(errno)
        }
        
        #if os(Linux)
            let result = Glibc.connect(sockfd, &info, socklen_t(sizeof(sockaddr)))
        #else
            let result = Darwin.connect(sockfd, &info, socklen_t(sizeof(sockaddr)))
        #endif
        
        if result == -1 {
            throw TCPClientError.ConnectFailed(errno)
        }
        
        return Connection(fileDescriptor: sockfd)
    }
}