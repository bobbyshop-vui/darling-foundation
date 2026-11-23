#import <Foundation/NSUserScriptTask.h>

@class NSArray<ObjectType>, NSError, NSFileHandle, NSString, NSURL;

NS_ASSUME_NONNULL_BEGIN

/* NSUserUnixTask: a Unix executable file, typically a shell script. */
@interface NSUserUnixTask : NSUserScriptTask {
    NSURL *_unixScriptURL;
    NSFileHandle *_unixStandardInput;
    NSFileHandle *_unixStandardOutput;
    NSFileHandle *_unixStandardError;
    BOOL _unixExecuted;
}

- (nullable instancetype)initWithURL:(NSURL *)url error:(NSError **)error;

@property (readonly, copy) NSURL *scriptURL;

@property (nullable, retain) NSFileHandle *standardInput;
@property (nullable, retain) NSFileHandle *standardOutput;
@property (nullable, retain) NSFileHandle *standardError;

typedef void (^NSUserUnixTaskCompletionHandler)(NSError *_Nullable error);
- (void)executeWithArguments:(nullable NSArray<NSString *> *)arguments completionHandler:(nullable NSUserUnixTaskCompletionHandler)handler;
- (void)executeWithCompletionHandler:(nullable void (^)(NSError * _Nullable error))handler;

@end

NS_ASSUME_NONNULL_END
