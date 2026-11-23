#import <Foundation/NSObject.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSDate.h>
#import <dispatch/dispatch.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NSBackgroundActivityResult) {
    NSBackgroundActivityResultFinished = 1,
    NSBackgroundActivityResultDeferred = 2,
};

typedef void (^NSBackgroundActivityCompletionHandler)(NSBackgroundActivityResult result);

@interface NSBackgroundActivityScheduler : NSObject {
    NSString *_identifier;
    NSQualityOfService _qualityOfService;
    BOOL _repeats;
    NSTimeInterval _interval;
    NSTimeInterval _tolerance;
    BOOL _toleranceSet;
    BOOL _shouldDefer;
    BOOL _scheduled;
    NSUInteger _generation;
    void (^_block)(NSBackgroundActivityCompletionHandler);
    dispatch_queue_t _queue;
}

- (instancetype)initWithIdentifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

@property (readonly, copy) NSString *identifier;
@property NSQualityOfService qualityOfService;
@property BOOL repeats;
@property NSTimeInterval interval;
@property NSTimeInterval tolerance;

- (void)scheduleWithBlock:(void (^)(NSBackgroundActivityCompletionHandler completionHandler))block;
- (void)invalidate;

@property (readonly) BOOL shouldDefer;

@end

NS_ASSUME_NONNULL_END
