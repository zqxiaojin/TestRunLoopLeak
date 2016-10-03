//
//  ViewController.m
//  TestRunLoopLeak
//
//  Created by liangjin on 9/22/16.
//  Copyright © 2016 LiangJin. All rights reserved.
//

#import "ViewController.h"


#pragma mark - for detect object dealloc
@interface Test : NSObject
@end
@implementation Test
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSLog(@"Test init");
    }
    return self;
}
- (id)autorelease
{
    return [super autorelease];
}
- (void)dealloc
{
    NSLog(@"Test dealloc");
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}
@end
void doSomeThing(void* info)
{
//    @autoreleasepool
    {
        
#if __has_feature(objc_arc)
    __autoreleasing
#endif 
    Test* t = [[Test alloc] init];
    [t description];
#if !__has_feature(objc_arc)
        [t autorelease];// it should call release after one loop
#endif
        
    }

}
void doSomeThingWithRunLoop()
{
    CFRunLoopRef runloop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    CFRunLoopSourceContext source_context = {0};
    CFRunLoopMode mode = CFRunLoopCopyCurrentMode(runloop);
    source_context.perform = doSomeThing;
    CFRunLoopSourceRef work_source = CFRunLoopSourceCreate(NULL,// allocator
                                                           0,// priority
                                                           &source_context);
    CFRunLoopAddSource(runloop,
                       work_source,
                       mode);
    CFRunLoopSourceSignal(work_source);
    CFRunLoopWakeUp(runloop);
    CFRelease(mode);
    CFRelease(work_source);
    
}


#pragma mark - for Protocol
@interface TestURLProtocol : NSURLProtocol
@end
@implementation TestURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [NSURLProtocol propertyForKey:@"TestURLProtocol" inRequest:request] == nil;
}
- (instancetype)initWithRequest:(NSURLRequest *)request
                 cachedResponse:(nullable NSCachedURLResponse *)cachedResponse
                         client:(nullable id <NSURLProtocolClient>)client
{
    
    return [super initWithRequest:request
                   cachedResponse:cachedResponse
                           client:client];
}
- (void)dealloc
{
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}
- (void)startLoading
{
    doSomeThingWithRunLoop();
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.apple.com"]];
    [NSURLProtocol setProperty:@"" forKey:@"TestURLProtocol" inRequest:req];
                                
    [NSURLConnection connectionWithRequest:req delegate:self];
}

- (void)stopLoading
{
    
}
- (nullable NSURLRequest *)connection:(NSURLConnection *)connection
                      willSendRequest:(NSURLRequest *)request
                     redirectResponse:(nullable NSURLResponse *)response
{
    return request;
}
- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response;
{
    [response description];
}

@end





@interface ViewController ()

@property (nonatomic,strong)UIWebView* webview;
@property (nonatomic,strong)NSURLConnection* con;
@end
#define TEST_CONNECTION 1

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [NSURLProtocol registerClass:[TestURLProtocol class]];
    
#if TEST_WEBVIEW
    self.webview = [[UIWebView alloc] initWithFrame:CGRectZero];
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com"]]];
    
    [self performSelector:@selector(delay) withObject:nil afterDelay:3.0f];
#elif TEST_CONNECTION
    self.con = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.apple.com"]] delegate:self];
#else
    NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(thread_run) object:nil];
    [thread start];
    [thread autorelease];
#endif

}

- (void)thread_run
{
    [self performSelector:@selector(thread_delay) withObject:nil afterDelay:0.5];
    [self performSelector:@selector(thread_delay) withObject:nil afterDelay:1111];
    do
    {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    } while (true);
}
- (void)thread_delay
{
    doSomeThingWithRunLoop();
}
- (nullable NSURLRequest *)connection:(NSURLConnection *)connection
                      willSendRequest:(NSURLRequest *)request
                     redirectResponse:(nullable NSURLResponse *)response
{
    return request;
}
- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response;
{
    [response description];
}
- (void)delay
{
    [self.webview stopLoading]; //just for stop protocol
}



@end
