#import <Foundation/NSPortNameServer.h>

/* NSMessagePortNameServer itself is declared in NSPortNameServer.h; this adds its class method. */
@interface NSMessagePortNameServer (NSMessagePortNameServerSharedInstance)

+ (id)sharedInstance;

@end
