//
//  Service.swift
//  Francis
//
//  Created by Andrew Shepard on 6/23/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Foundation

//- (void)dnssdServiceWillResolve:(nonnull DNSSDService *)service;
//
///**
// Called when the service successfully resolves.  The resolve will be stopped
// immediately after this delegate method returns.
//
// @param service The service that resolved an address
// */
//- (void)dnssdServiceDidResolveAddress:(nonnull DNSSDService *)service;
//
///**
// Called when the service fails to resolve.  The resolve will be stopped
// immediately after this delegate method returns.
//
// @param service The service
// @param error An error if any occurred; otherwise `nil`.
// */
//- (void)dnssdService:(nonnull DNSSDService *)service didNotResolve:(nullable NSError *)error;
//
///**
// Called when a resolve stops (except if you call -stop on it).
//
// @param service The service that stopped
// */
//- (void)dnssdServiceDidStop:(nonnull DNSSDService *)service;

protocol ServiceDelegate: class {
    
    /// Called when the service successfully resolves.  The resolve will be stopped
    /// immediately after this delegate method returns.
    ///
    /// - Parameter service: The service that resolved an address
    func serviceWillResolve(_ service: Service)
}

typealias ReplyCallback = (DNSServiceRef?, DNSServiceFlags, UInt32, DNSServiceErrorType, UnsafePointer<Int8>?, UnsafePointer<Int8>?, UInt16, UInt16, UnsafePointer<UInt8>?, UnsafeMutableRawPointer?) -> Void

func replyCallback(sdRef: DNSServiceRef?, flags: DNSServiceFlags, interfaceIndex: UInt32, errorCode: DNSServiceErrorType, fullname:  UnsafePointer<Int8>?, hosttarget:  UnsafePointer<Int8>?, port: UInt16, txtLen: UInt16, txtRecord:  UnsafePointer<UInt8>?, context: UnsafeMutableRawPointer?) {
    
}

let contextPtr = UnsafeMutableRawPointer(bitPattern: 0)

class Service {
    let domain: String
    let type: String
    let name: String
    
    private(set) var resolvedHost: String?
    private(set) var resolvedPort: Int?
    private(set) var entries: [String: String] = [:]
    
    private var sdRef: DNSServiceRef?
    private var timeoutTimer: Timer?
    
    weak var delegate: ServiceDelegate?
    
    init(domain: String, type: String, name: String) {
        self.domain = domain
        self.type = type
        self.name = name
    }
    
//    typedef void (*DNSServiceResolveReply)(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *fullname, const char *hosttarget, uint16_t port, uint16_t txtLen, const unsigned char *txtRecord, void *context);
    
    /// Starts a resolve.  Starting a resolve on a service that is currently resolving
    /// is a no-op.  If the resolve does not complete within 30 seconds, it will fail
    /// with a time out.
    ///
    /// - Parameter interface: the interface to start resolving on
    func startResolve(on interface: DNSSDInterfaceType) {
        if self.sdRef == nil {
            var errorCode: DNSServiceErrorType
            
            withUnsafePointer(to: self) { (ptr) in

            }
            

            if errorCode == kDNSServiceErr_NoError {
                
                print("no error")
            } else {
                print("erro: \(errorCode)")
            }
        }
        
        
//        if (self.sdRef == NULL) {
//            DNSServiceErrorType errorCode;
//
//            errorCode = DNSServiceResolve(&self->_sdRef, 0, interface, [self.name UTF8String], [self.type UTF8String], [self.domain UTF8String], ResolveReplyCallback, (__bridge void *)(self));
//            if (errorCode == kDNSServiceErr_NoError) {
//                errorCode = DNSServiceSetDispatchQueue(self.sdRef, dispatch_get_main_queue());
//            }
//            if (errorCode == kDNSServiceErr_NoError) {
//
//                // Service resolution /never/ times out.  This is convenient in some circumstances,
//                // but it's generally best to use some reasonable timeout.  Here we use an NSTimer
//                // to trigger a failure if we spend more than 30 seconds waiting for the resolve.
//
//                self.resolveTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(didFireResolveTimeoutTimer:) userInfo:nil repeats:NO];
//
//                if ([self.delegate respondsToSelector:@selector(dnssdServiceWillResolve:)]) {
//                    [self.delegate dnssdServiceWillResolve:self];
//                }
//            } else {
//                [self stopWithError:[NSError errorWithDomain:NSNetServicesErrorDomain code:errorCode userInfo:nil] notify:YES];
//            }
//        }
    }
    
    /// Stops a resolve.  Stopping a resolve on a service that is not resolving is a no-op.
    func stop() {
        
    }
}
