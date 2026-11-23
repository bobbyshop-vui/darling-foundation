#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@class NSError, NSXPCConnection;

NS_ASSUME_NONNULL_BEGIN

#ifndef NSFileProviderServiceName_DEFINED
#define NSFileProviderServiceName_DEFINED
typedef NSString * NSFileProviderServiceName;
#endif

/* Instances are obtained from -[NSFileManager getFileProviderServicesForItemAtURL:completionHandler:]. */
@interface NSFileProviderService : NSObject {
    NSString *_name;
}

- (void)getFileProviderConnectionWithCompletionHandler:(void (^)(NSXPCConnection * _Nullable connection, NSError * _Nullable error))completionHandler;

@property (readonly, copy) NSFileProviderServiceName name;

/* Darling: creates a service description with the given name. */
- (instancetype)initWithName:(NSFileProviderServiceName)name;

@end

NS_ASSUME_NONNULL_END
