#import <Foundation/NSObject.h>

@class NSURL, NSError;

@interface NSUserScriptTask : NSObject {
@protected
    NSURL *_scriptURL;
}

- (instancetype)initWithURL:(NSURL *)url error:(NSError **)error;
@property (readonly, copy) NSURL *scriptURL;
@end

@interface NSUserAppleScriptTask : NSUserScriptTask {}
@end
