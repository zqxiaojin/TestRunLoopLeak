# TestRunLoopLeak
iOS 10 NSURLProtocol's RunLoop leaks memory when it work with CFRunLoopSource.
It will lead to _nano_vet_and_size_of_live crash in iOS 10.
