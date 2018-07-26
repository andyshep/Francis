/*
    File:       DNSSDService.m

    Contains:   Represents a Bonjour service found by the low-level DNS-SD API.

    Written by: DTS

    Copyright:  Copyright (c) 2011 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "DNSSDService.h"

#include <dns_sd.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#pragma mark * DNSSDService

@interface DNSSDService ()

// read-write versions of public properties

@property (copy, readwrite) NSString *resolvedHost;
@property (copy, readwrite) NSString *resolvedIPAddress;
@property (assign, readwrite) NSUInteger resolvedPort;
@property (copy, readwrite) NSDictionary<NSString *, NSString *> *entries;

// private properties

@property (assign, readwrite) DNSServiceRef sdRef;
@property (retain, readwrite) NSTimer *resolveTimeoutTimer;

// forward declarations

- (void)stopWithError:(NSError *)error notify:(BOOL)notify;

@end

@implementation DNSSDService

- (id)initWithDomain:(NSString *)domain type:(NSString *)type name:(NSString *)name
    // See comment in header.
{
    assert(domain != nil);
    assert([domain length] != 0);
    assert( ! [domain hasPrefix:@"."] );
    assert(type != nil);
    assert([type length] != 0);
    assert( ! [type hasPrefix:@"."] );
    assert(name != nil);
    assert([name length] != 0);
    self = [super init];
    if (self != nil) {
        if ( ! [domain hasSuffix:@"."] ) {
            domain = [domain stringByAppendingString:@"."];
        }
        if ( ! [type hasSuffix:@"."] ) {
            type = [type stringByAppendingString:@"."];
        }
        self->_domain = [domain copy];
        self->_type = [type copy];
        self->_name = [name copy];
    }
    return self;
}

- (void)dealloc
{
    if (self->_sdRef != NULL) {
        DNSServiceRefDeallocate(self->_sdRef);
    }
    [self->_resolveTimeoutTimer invalidate];
}

- (id)copyWithZone:(NSZone *)zone
    // Part of the NSCopying protocol, as discussed in the header.
{
    return [[[self class] allocWithZone:zone] initWithDomain:self.domain type:self.type name:self.name];
}

// We have to implement -isEqual: and -hash to allow the object to function correctly 
// when placed in sets.

- (BOOL)isEqual:(id)object
    // See comment in header.
{
    DNSSDService *other;

    // Boilerplate stuff.
    
    if (object == self) {
        return YES;
    }
    if ( ! [object isKindOfClass:[self class]] ) {
        return NO;
    }
    
    // Compare the domain, type and name.
    
    other = (DNSSDService *) object;
    return [self.domain isEqualToString:other.domain] && [self.type isEqualToString:other.type] && [self.name isEqualToString:other.name];
}

- (NSUInteger)hash
    // See comment in header.
{
    return [self.domain hash] ^ [self.type hash] ^ [self.name hash];
}

- (NSString *)description
    // We override description to make it easier to debug operations that involve lots of DNSSDService 
    // objects.  This is really helpful, for example, when you have an NSSet of discovered services and 
    // you want to check that new services are being added correctly.
{
    return [NSString stringWithFormat:@"%@ {%@, %@, %@}", [super description], self.domain, self.type, self.name];
}

- (void)resolveReplyWithTarget:(NSString *)resolvedHost
                          port:(NSUInteger)port interface:(uint32_t)interface
                       entries:(NSDictionary<NSString *, NSString *> *)entries
    // Called when DNS-SD tells us that a resolve has succeeded.
{
    assert(resolvedHost != nil);
    
    // Latch the results.
    
    self.resolvedHost = resolvedHost;
    self.resolvedPort = port;
    self.entries = entries;
    
    // Find the ip address
    
    [self startGetAddressOnInterface:(DNSSDInterfaceType)interface];
}

- (void)addressReplyWithAddress:(NSString *)address
{
    assert(address != nil);
    
    // Latch the results
    
    self.resolvedIPAddress = address;
    
    NSMutableDictionary *entries = [NSMutableDictionary dictionaryWithDictionary:self.entries];
    
    [entries setObject:address forKey:@"IP Address"];
    
    self.entries = entries;
    
    // Call the delegate
    
    if ([self.delegate respondsToSelector:@selector(dnssdServiceDidResolveAddress:)]) {
        [self.delegate dnssdServiceDidResolveAddress:self];
    }

    // Stop resolving.  It's common for clients to forget to do this, so we always do
    // it as a matter of policy.  If you want to issue a long-running resolve, you're going
    // to have tweak this code.
    
    [self stopWithError:nil notify:YES];
}

static void ResolveReplyCallback(
    DNSServiceRef           sdRef,
    DNSServiceFlags         flags,
    uint32_t                interfaceIndex,
    DNSServiceErrorType     errorCode,
    const char *            fullname,
    const char *            hosttarget,
    uint16_t                port,
    uint16_t                txtLen,
    const unsigned char *   txtRecord,
    void *                  context
)
    // Called by DNS-SD when something happens with the resolve operation.
{
    DNSSDService *       obj;
    #pragma unused(interfaceIndex)
    
    assert([NSThread isMainThread]);        // because sdRef dispatches to the main queue
    
    obj = (__bridge DNSSDService *) context;
    assert([obj isKindOfClass:[DNSSDService class]]);
//    assert(sdRef == obj->_sdRef);
    #pragma unused(sdRef)
    #pragma unused(flags)
    #pragma unused(fullname)
    #pragma unused(txtLen)
    #pragma unused(txtRecord)
    
    if (errorCode == kDNSServiceErr_NoError) {
        NSString *target = [NSString stringWithUTF8String:hosttarget];
        NSString *textRecord = [NSString stringWithUTF8String:(const char *)txtRecord];
        #pragma unused(textRecord)
        NSUInteger port = ntohs(port);
        
        NSMutableDictionary<NSString *, NSString *> *entries = [NSMutableDictionary dictionary];
        
        uint16_t count = TXTRecordGetCount(txtLen, txtRecord);
        for (uint16_t index = 0; index < count; index++) {
            uint8_t valueLen = 0;
            const void *valueRef = NULL;
            
            char keyBuf[256];
            DNSServiceErrorType errorCode;
            
            errorCode = TXTRecordGetItemAtIndex(txtLen, txtRecord, index, 256, keyBuf, &valueLen, &valueRef);
            
            if (errorCode != 0) {
                continue;
            }
            
            NSUInteger length = valueLen;
            NSString *value = [[NSString alloc] initWithBytes:valueRef length:length encoding:NSUTF8StringEncoding];
            NSString *key = [[NSString alloc] initWithUTF8String:keyBuf];
            
            [entries setValue:value forKey:key];
        }
        
        [obj resolveReplyWithTarget:target port:port interface:interfaceIndex entries:entries];
    } else {
        [obj stopWithError:[NSError errorWithDomain:NSNetServicesErrorDomain code:errorCode userInfo:nil] notify:YES];
    }
}

static void GetAddrInfoReplyCallback(
    DNSServiceRef sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    DNSServiceErrorType errorCode,
    const char *hostname,
    const struct sockaddr *address,
    uint32_t ttl,
    void *context
)
    // Called by DNS-SD when something happens with the get address operation.
{
    DNSSDService *obj;
    
    // because sdRef dispatches to the main queue
    assert([NSThread isMainThread]);
    
    obj = (__bridge DNSSDService *) context;
    assert([obj isKindOfClass:[DNSSDService class]]);
    
    if (errorCode == kDNSServiceErr_NoError) {
        struct sockaddr_in *address_in = (struct sockaddr_in *)address;
        
        if (address_in->sin_family == AF_INET6) {
            // TODO: implement
        } else {
            const char *ip_address = inet_ntoa(address_in->sin_addr);
            NSString *ipAddress = [NSString stringWithUTF8String:ip_address];
            
            [obj addressReplyWithAddress:ipAddress];
        }
    } else {
        [obj stopWithError:[NSError errorWithDomain:NSNetServicesErrorDomain code:errorCode userInfo:nil] notify:YES];
    }
}

- (void)startResolveOnInterface:(DNSSDInterfaceType)interface
    // See comment in header.
{
    if (self.sdRef == NULL) {
        DNSServiceErrorType errorCode;

        errorCode = DNSServiceResolve(&self->_sdRef, 0, interface, [self.name UTF8String], [self.type UTF8String], [self.domain UTF8String], ResolveReplyCallback, (__bridge void *)(self));
        
        if (errorCode == kDNSServiceErr_NoError) {
            errorCode = DNSServiceSetDispatchQueue(self.sdRef, dispatch_get_main_queue());
        }
        if (errorCode == kDNSServiceErr_NoError) {

            // Service resolution /never/ times out.  This is convenient in some circumstances, 
            // but it's generally best to use some reasonable timeout.  Here we use an NSTimer 
            // to trigger a failure if we spend more than 30 seconds waiting for the resolve.

            self.resolveTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(didFireResolveTimeoutTimer:) userInfo:nil repeats:NO];

            if ([self.delegate respondsToSelector:@selector(dnssdServiceWillResolve:)]) {
                [self.delegate dnssdServiceWillResolve:self];
            }
        } else {
            [self stopWithError:[NSError errorWithDomain:NSNetServicesErrorDomain code:errorCode userInfo:nil] notify:YES];
        }
    }
}

- (void)didFireResolveTimeoutTimer:(NSTimer *)timer
{
    assert(timer == self.resolveTimeoutTimer);
    [self stopWithError:[NSError errorWithDomain:NSNetServicesErrorDomain code:kDNSServiceErr_Timeout userInfo:nil] notify:YES];
}

- (void)stopWithError:(NSError *)error notify:(BOOL)notify
    // An internal bottleneck for shutting down the object.
{
    if (notify) {
        if (error != nil) {
            if ([self.delegate respondsToSelector:@selector(dnssdService:didNotResolve:)]) {
                [self.delegate dnssdService:self didNotResolve:error];
            }
        }
    }
    if (self.sdRef != NULL) {
        DNSServiceRefDeallocate(self.sdRef);
        self.sdRef = NULL;
    }
    [self.resolveTimeoutTimer invalidate];
    self.resolveTimeoutTimer = nil;
    if (notify) {
        if ([self.delegate respondsToSelector:@selector(dnssdServiceDidStop:)]) {
            [self.delegate dnssdServiceDidStop:self];
        }
    }
}

- (void)startGetAddressOnInterface:(DNSSDInterfaceType)interface {
    DNSServiceErrorType errorCode;
    
    errorCode = DNSServiceGetAddrInfo(&self->_sdRef, kDNSServiceFlagsForceMulticast, 0, kDNSServiceProtocol_IPv4, [self.resolvedHost UTF8String], GetAddrInfoReplyCallback, (__bridge void *)(self));
    
    if (errorCode == kDNSServiceErr_NoError) {
        errorCode = DNSServiceSetDispatchQueue(self.sdRef, dispatch_get_main_queue());
    }
    
    if (errorCode == kDNSServiceErr_NoError) {
        
    }
}

- (void)stop
    // See comment in header.
{
    [self stopWithError:nil notify:NO];
}

@end
