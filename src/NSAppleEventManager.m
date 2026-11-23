#import <Foundation/NSAppleEventManager.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <CarbonCore/MacErrors.h>

static NSAppleEventManager* instance = nil;

/*
 * Registered handlers, keyed by the 64-bit (class << 32 | ID) pair.  Each
 * entry holds the handler (retained, as AppKit does) and its selector.
 */
static NSMutableDictionary *handlerTable(void)
{
    static NSMutableDictionary *table = nil;
    @synchronized([NSAppleEventManager class]) {
        if (table == nil)
            table = [[NSMutableDictionary alloc] init];
    }
    return table;
}

static NSNumber *handlerKey(AEEventClass eventClass, AEEventID eventID)
{
    return [NSNumber numberWithUnsignedLongLong:
            ((unsigned long long) eventClass << 32) | (unsigned long long) eventID];
}

@implementation NSAppleEventManager

+ (NSAppleEventManager *)sharedAppleEventManager
{
    @synchronized(self)
    {
        if (instance == nil)
            instance = [[NSAppleEventManager alloc] init];
    }
    return instance;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    return signature ?: [NSMethodSignature signatureWithObjCTypes: "v@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"Stub called: %@ in %@", NSStringFromSelector([anInvocation selector]), [self class]);
}

- (OSErr)dispatchRawAppleEvent:(const AppleEvent *)theAppleEvent
                 withRawReply:(AppleEvent *)theReply
                handlerRefCon:(SRefCon)handlerRefCon
{
    /*
     * Reading the event's class and ID needs a working
     * NSAppleEventDescriptor, which Foundation does not have yet, so a raw
     * event cannot be routed to the handlers registered below.
     */
    return errAEEventNotHandled;
}

- (void) setEventHandler: (id) handler
             andSelector: (SEL) selector
           forEventClass: (AEEventClass) eventClass
              andEventID: (AEEventID) eventID
{
    NSMutableDictionary *table = handlerTable();
    @synchronized(table) {
        if (handler == nil || selector == NULL) {
            [table removeObjectForKey: handlerKey(eventClass, eventID)];
            return;
        }
        [table setObject: [NSArray arrayWithObjects: handler,
                                   NSStringFromSelector(selector), nil]
                  forKey: handlerKey(eventClass, eventID)];
    }
}

- (void) removeEventHandlerForEventClass: (AEEventClass) eventClass
                              andEventID: (AEEventID) eventID
{
    NSMutableDictionary *table = handlerTable();
    @synchronized(table) {
        [table removeObjectForKey: handlerKey(eventClass, eventID)];
    }
}

/* No Apple event is ever being handled, so there is no current event. */
- (NSAppleEventDescriptor *) currentAppleEvent
{
    return nil;
}

- (NSAppleEventDescriptor *) currentReplyAppleEvent
{
    return nil;
}

@end
