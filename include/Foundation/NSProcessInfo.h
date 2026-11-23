#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>

enum {
    NSWindowsNTOperatingSystem = 1,
    NSWindows95OperatingSystem,
    NSSolarisOperatingSystem,
    NSHPUXOperatingSystem,
    NSMACHOperatingSystem,
    NSSunOSOperatingSystem,
    NSOSF1OperatingSystem,
    NSAndroidOperatingSystem,
};

typedef struct
{
	NSInteger majorVersion;
	NSInteger minorVersion;
	NSInteger patchVersion;
}
NSOperatingSystemVersion;

@class NSArray, NSString, NSDictionary;

@interface NSProcessInfo : NSObject
{
    NSDictionary *environment; // not used it seems
    NSArray *arguments; // is really mutable
    NSString *hostName; // singly created
    NSString *name; // singly created, but replaceable
    NSInteger automaticTerminationOptOutCounter;
}

+ (NSProcessInfo *)processInfo;

- (NSDictionary *)environment;
- (NSArray *)arguments;
- (NSString *)hostName;
- (NSString *)processName;
- (int)processIdentifier;
- (void)setProcessName:(NSString *)newName;
- (NSString *)globallyUniqueString;
- (NSUInteger)operatingSystem;
- (NSString *)operatingSystemName;
- (NSString *)operatingSystemVersionString;
- (NSUInteger)processorCount;
- (NSUInteger)activeProcessorCount;
- (unsigned long long)physicalMemory;
- (NSTimeInterval)systemUptime;
- (NSOperatingSystemVersion)operatingSystemVersion;
- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version;
- (void)disableAutomaticTermination:(NSString *)reason;
- (void)disableSuddenTermination;
- (void)enableAutomaticTermination:(NSString *)reason;
- (void)enableSuddenTermination;
- (NSString *)userName;

// Activity APIs are used by newer macOS applications to bracket work that
// should not be interrupted by system sleep or termination.
- (id)beginActivityWithOptions:(NSUInteger)options reason:(NSString *)reason;
- (void)endActivity:(id)activity;

@end

@interface NSProcessInfo (NSProcessInfoPlatform)
-(BOOL)isMacCatalystApp;
-(BOOL)isiOSAppOnMac;
@property(readonly, getter=isMacCatalystApp) BOOL macCatalystApp;
@property(readonly, getter=isiOSAppOnMac) BOOL iOSAppOnMac;
@end

#ifdef DARLING
FOUNDATION_EXPORT void __NSInitializeProcess(int argc,const char *argv[]);
#endif
