#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

enum TCPListenerError: ErrorType {
    case GetAddrInfoFailed(Int32)
    case BindFailed
    case ListenFailed(Int32)
    case AcceptFailed(Int32)
    case GetSockNameFailed(Int32)
    case CloseFailed(Int32)
}

class TCPListener: Listener {
    var port: Int32
    
    private var listenfd: Int32 = -1
    
    required init(port: Int32) throws {
        self.port = port
        try startSocket()
    }
    
    private func startSocket() throws {
        var res = UnsafeMutablePointer<addrinfo>()
        var p = UnsafeMutablePointer<addrinfo>()
        
        var hints = addrinfo()
        memset(&hints, 0, sizeof(addrinfo))
        
        hints.ai_flags = AI_PASSIVE
        hints.ai_family = AF_UNSPEC
        #if os(Linux)
            hints.ai_socktype = Int32(SOCK_STREAM.rawValue)
        #else
            hints.ai_socktype = SOCK_STREAM
        #endif
        
        let status = getaddrinfo(nil, String(port), &hints, &res)
        
        if status != 0 {
            throw TCPListenerError.GetAddrInfoFailed(status)
        }
        
        p = res
        while p != nil {
            listenfd = socket(p.memory.ai_family, p.memory.ai_socktype, 0)
            
            if listenfd == -1 {
                continue
            }
            
            if bind(listenfd, p.memory.ai_addr, p.memory.ai_addrlen) == 0 {
                break
            }
            
            p = p.memory.ai_next
        }
        
        if p == nil {
            throw TCPListenerError.BindFailed
        }
        
        freeaddrinfo(res)
        
        if listen(listenfd, SOMAXCONN) != 0 {
            throw TCPListenerError.ListenFailed(errno)
        }
    }
    
    func accept() throws -> Connection {
        
        var clientaddr = sockaddr()
        
        #if !os(Linux)
            clientaddr.sa_len = 0
        #endif
        
        clientaddr.sa_family = 0
        clientaddr.sa_data = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        
        var addrlen = socklen_t(sizeof(sockaddr))
        
        #if os(Linux)
            let descriptor = Glibc.accept(listenfd, &clientaddr, &addrlen)
        #else
            let descriptor = Darwin.accept(listenfd, &clientaddr, &addrlen)
        #endif
        
        if descriptor < 0 {
            throw TCPListenerError.AcceptFailed(errno)
        }
        
        return Connection(fileDescriptor: descriptor)
    }
    
    func close() throws {
        #if os(Linux)
            let result = Glibc.close(listenfd)
        #else
            let result = Darwin.close(listenfd)
        #endif
        if result == -1 {
            throw TCPListenerError.CloseFailed(errno)
        }
    }
}