#import <Foundation/NSBackgroundActivityScheduler.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <dispatch/dispatch.h>

@implementation NSBackgroundActivityScheduler

- (instancetype)init
{
    [self release];
    [NSException raise:NSInvalidArgumentException format:@"-[NSBackgroundActivityScheduler init]: use -initWithIdentifier:"];
    return nil;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    if (![identifier length]) {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"NSBackgroundActivityScheduler requires a non-empty identifier"];
        return nil;
    }
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _qualityOfService = NSQualityOfServiceBackground;
        _interval = 0;
        _queue = dispatch_queue_create([identifier UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSString *)identifier
{
    return _identifier;
}

- (NSQualityOfService)qualityOfService
{
    return _qualityOfService;
}

- (void)setQualityOfService:(NSQualityOfService)qualityOfService
{
    _qualityOfService = qualityOfService;
}

- (BOOL)repeats
{
    return _repeats;
}

- (void)setRepeats:(BOOL)repeats
{
    _repeats = repeats;
}

- (NSTimeInterval)interval
{
    return _interval;
}

- (void)setInterval:(NSTimeInterval)interval
{
    _interval = interval;
}

- (NSTimeInterval)tolerance
{
    return _toleranceSet ? _tolerance : _interval / 2.0;
}

- (void)setTolerance:(NSTimeInterval)tolerance
{
    _tolerance = tolerance;
    _toleranceSet = YES;
}

- (BOOL)shouldDefer
{
    return _shouldDefer;
}

- (dispatch_queue_priority_t)_priority
{
    if (_qualityOfService >= NSQualityOfServiceUserInitiated)
        return DISPATCH_QUEUE_PRIORITY_HIGH;
    if (_qualityOfService >= NSQualityOfServiceUtility || _qualityOfService == NSQualityOfServiceDefault)
        return DISPATCH_QUEUE_PRIORITY_DEFAULT;
    return DISPATCH_QUEUE_PRIORITY_BACKGROUND;
}

- (void)_scheduleNextWithGeneration:(NSUInteger)generation delay:(NSTimeInterval)delay
{
    [self retain];
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
    dispatch_after(when, _queue, ^{
        BOOL run;
        void (^block)(NSBackgroundActivityCompletionHandler) = nil;
        @synchronized (self) {
            run = _scheduled && _generation == generation;
            if (run)
                block = [_block retain];
        }
        if (run && block) {
            _shouldDefer = NO;
            block(^(NSBackgroundActivityResult result) {
                BOOL again;
                NSTimeInterval next;
                @synchronized (self) {
                    again = _scheduled && _generation == generation &&
                            (_repeats || result == NSBackgroundActivityResultDeferred);
                    next = (result == NSBackgroundActivityResultDeferred) ? MAX(_interval / 10.0, 1.0) : _interval;
                    if (!again && _generation == generation)
                        _scheduled = NO;
                }
                if (again)
                    [self _scheduleNextWithGeneration:generation delay:next];
            });
        }
        [block release];
        [self release];
    });
}

- (void)scheduleWithBlock:(void (^)(NSBackgroundActivityCompletionHandler))block
{
    NSUInteger generation;
    @synchronized (self) {
        [_block release];
        _block = [block copy];
        _scheduled = YES;
        generation = ++_generation;
    }
    [self _scheduleNextWithGeneration:generation delay:_interval];
}

- (void)invalidate
{
    @synchronized (self) {
        _scheduled = NO;
        _generation++;
        [_block release];
        _block = nil;
    }
}

- (void)dealloc
{
    [_block release];
    [_identifier release];
    if (_queue)
        dispatch_release(_queue);
    [super dealloc];
}

@end
