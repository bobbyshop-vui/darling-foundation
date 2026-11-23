#import <Foundation/NSUserScriptTask.h>

@class NSDictionary<KeyType, ObjectType>, NSError, NSString, NSURL;

NS_ASSUME_NONNULL_BEGIN

/* NSUserAutomatorTask: an Automator workflow. */
@interface NSUserAutomatorTask : NSUserScriptTask {
    NSURL *_automatorScriptURL;
    NSDictionary *_variables;
}

- (nullable instancetype)initWithURL:(NSURL *)url error:(NSError **)error;

@property (readonly, copy) NSURL *scriptURL;

@property (nullable, copy) NSDictionary<NSString *, id> *variables;

typedef void (^NSUserAutomatorTaskCompletionHandler)(id _Nullable result, NSError * _Nullable error);
- (void)executeWithInput:(nullable id <NSSecureCoding>)input completionHandler:(nullable NSUserAutomatorTaskCompletionHandler)handler;
- (void)executeWithCompletionHandler:(nullable void (^)(NSError * _Nullable error))handler;

@end

NS_ASSUME_NONNULL_END
