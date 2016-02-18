#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import StreamKit

class Connection: IOStream {
    
    private static func ntop(inout addr: sockaddr) -> String? {
        var charArray = [CChar]()
        
        if addr.sa_family == sa_family_t(AF_INET) {
            charArray = [CChar](count: Int(INET_ADDRSTRLEN), repeatedValue: 0)
            
            withUnsafePointer(&addr) { (ptr: UnsafePointer<sockaddr>) -> Void in
                let ipv4: UnsafePointer<sockaddr_in> = unsafeBitCast(ptr, UnsafePointer<sockaddr_in>.self)
                var ipAddr = ipv4.memory.sin_addr
                inet_ntop(AF_INET, &ipAddr, &charArray, socklen_t(INET_ADDRSTRLEN))
            }
            
        } else if addr.sa_family == sa_family_t(AF_INET6) {
            charArray = [CChar](count: Int(INET6_ADDRSTRLEN), repeatedValue: 0)
            
            withUnsafePointer(&addr) { (ptr: UnsafePointer<sockaddr>) -> Void in
                let ipv6: UnsafePointer<sockaddr_in6> = unsafeBitCast(ptr, UnsafePointer<sockaddr_in6>.self)
                var ipAddr = ipv6.memory.sin6_addr
                inet_ntop(AF_INET6, &ipAddr, &charArray, socklen_t(INET6_ADDRSTRLEN))
            }
        }
        
        return String.fromCString(charArray)
    }
    
    var remoteAddr: String {
        get {
            var addrlen = socklen_t(sizeof(sockaddr))
            var remoteaddr = sockaddr()
            let result = getpeername(fileDescriptor, &remoteaddr, &addrlen)
            
            if result == -1 {
                return ""
            }
            
            return Connection.ntop(&remoteaddr)!
        }
    }
    
    var localAddr: String {
        get {
            var addrlen = socklen_t(sizeof(sockaddr))
            var localaddr = sockaddr()
            let result = getsockname(fileDescriptor, &localaddr, &addrlen)
            
            if result == -1 {
                return ""
            }
            
            return Connection.ntop(&localaddr)!
        }
    }
}