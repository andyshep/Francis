//
//  DNSSDInterfaceType.h
//  Francis
//
//  Created by Andrew Shepard on 4/8/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

#ifndef DNSSDInterfaceType_h
#define DNSSDInterfaceType_h


#endif /* DNSSDInterfaceType_h */

/**
 Interface types
 
 - DNSSDInterfaceTypeAny: All intefaces
 - DNSSDInterfaceTypeLocalOnly: Local only
 - DNSSDInterfaceTypeUnicast: Unicast
 - DNSSDInterfaceTypeP2P: Peer-to-peer
 - DNSSDInterfaceTypeBLE: Bluetooth Low Energy
 */
typedef NS_ENUM(u_int32_t, DNSSDInterfaceType) {
    DNSSDInterfaceTypeAny = 0,
    DNSSDInterfaceTypeLocalOnly = ((uint32_t)-1),
    DNSSDInterfaceTypeUnicast = ((uint32_t)-2),
    DNSSDInterfaceTypeP2P = ((uint32_t)-3),
    DNSSDInterfaceTypeBLE = ((uint32_t)-4)
};
