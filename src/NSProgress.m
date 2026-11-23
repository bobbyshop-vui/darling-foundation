//
//  NSProgress.m
//  Foundation
//
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/NSProgress.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSThread.h>
#import "NSProgressInternal.h"

NSString * const NSProgressEstimatedTimeRemainingKey = @"NSProgressEstimatedTimeRemainingKey";
NSString * const NSProgressThroughputKey = @"NSProgressThroughputKey";
NSString * const NSProgressKindFile = @"NSProgressKindFile";
NSString * const NSProgressFileOperationKindKey = @"NSProgressFileOperationKindKey";
NSString * const NSProgressFileOperationKindDownloading = @"NSProgressFileOperationKindDownloading";
NSString * const NSProgressFileOperationKindDecompressingAfterDownloading = @"NSProgressFileOperationKindDecompressingAfterDownloading";
NSString * const NSProgressFileOperationKindReceiving = @"NSProgressFileOperationKindReceiving";
NSString * const NSProgressFileOperationKindCopying = @"NSProgressFileOperationKindCopying";
NSString * const NSProgressFileURLKey = @"NSProgressFileURLKey";
NSString * const NSProgressFileTotalCountKey = @"NSProgressFileTotalCountKey";
NSString * const NSProgressFileCompletedCountKey = @"NSProgressFileCompletedCountKey";
NSString * const NSProgressFileAnimationImageKey = @"NSProgressFlyToImageKey";
NSString * const NSProgressFileAnimationImageOriginalRectKey = @"NSProgressFileAnimationImageOriginalRectKey";
NSString * const NSProgressFileIconKey = @"NSProgressFileIconKey";

// TODO: KVO
// (actually, TODO: pretty much all of NSProgress)
// also, the self-synchronization in basically every method is pretty inefficient

static NSString * const NSProgressCurrentStackKey = @"NSProgressCurrentStack";

static NSMutableArray *NSProgressCurrentStack(BOOL create)
{
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSMutableArray *stack = [threadDictionary objectForKey:NSProgressCurrentStackKey];
    if (!stack && create)
    {
        stack = [NSMutableArray array];
        [threadDictionary setObject:stack forKey:NSProgressCurrentStackKey];
    }
    return stack;
}

@implementation NSProgress

@synthesize cancellationHandler = _cancellationHandler;
@synthesize pausingHandler = _pausingHandler;
@synthesize resumingHandler = _resumingHandler;

+ (instancetype)currentProgress
{
    NSMutableArray *stack = NSProgressCurrentStack(NO);
    NSDictionary *frame = [stack lastObject];
    return [frame objectForKey:@"progress"];
}

+ (instancetype)progressWithTotalUnitCount: (int64_t)unitCount
{
    NSMutableArray *stack = NSProgressCurrentStack(NO);
    NSMutableDictionary *frame = [stack lastObject];
    NSProgress *parent = [frame objectForKey:@"progress"];
    if (parent)
    {
        NSProgress *progress = [[self alloc] initWithParent:parent userInfo:nil];
        progress->_totalUnitCount = unitCount;
        progress->_parentPendingUnitCount = 0;
        [[frame objectForKey:@"children"] addObject:progress];
        return [progress autorelease];
    }

    NSProgress *progress = [[self alloc] initWithParent:nil userInfo:nil];
    progress->_totalUnitCount = unitCount;
    return [progress autorelease];
}

+ (instancetype)progressWithTotalUnitCount:(int64_t)unitCount parent:(NSProgress *)parent pendingUnitCount:(int64_t)portionOfParentTotalUnitCount
{
    NSProgress *progress = [[self alloc] initWithParent:parent userInfo:nil];
    progress->_totalUnitCount = unitCount;
    progress->_parentPendingUnitCount = portionOfParentTotalUnitCount;
    return [progress autorelease];
}

+ (instancetype)discreteProgressWithTotalUnitCount: (int64_t)unitCount
{
    NSProgress *progress = [[self alloc] initWithParent:nil userInfo:nil];
    progress->_totalUnitCount = unitCount;
    return [progress autorelease];
}

- (void)dealloc
{
    for (NSProgress *child in _childProgresses)
    {
        if (child->_parentProgress == self)
        {
            child->_parentProgress = nil;
        }
    }
    [_childProgresses release];
    [_userInfo release];
    [_localizedDescription release];
    [_localizedAdditionalDescription release];
    [_kind release];
    [_cancellationHandler release];
    [_pausingHandler release];
    [_resumingHandler release];
    [super dealloc];
}

- (instancetype)initWithParent: (NSProgress*)parent userInfo: (NSDictionary<NSString*, id>*)userInfo
{
    if (self = [super init]) {
        _userInfo = userInfo ? [userInfo mutableCopy] : [[NSMutableDictionary alloc] init];
        if (parent)
        {
            _parentProgress = parent;
            @synchronized(parent)
            {
                if (!parent->_childProgresses)
                {
                    parent->_childProgresses = [[NSMutableArray alloc] init];
                }
                [parent->_childProgresses addObject:self];
            }
        }
    }
    return self;
}

- (void)becomeCurrentWithPendingUnitCount:(int64_t)unitCount
{
    NSMutableDictionary *frame = [NSMutableDictionary dictionary];
    NSMutableArray *children = [NSMutableArray array];
    [frame setObject:self forKey:@"progress"];
    [frame setObject:[NSNumber numberWithLongLong:unitCount] forKey:@"pending"];
    [frame setObject:children forKey:@"children"];
    [NSProgressCurrentStack(YES) addObject:frame];
}

- (void)resignCurrent
{
    NSMutableArray *stack = NSProgressCurrentStack(NO);
    NSUInteger frameIndex = [stack count];
    while (frameIndex > 0)
    {
        frameIndex--;
        NSMutableDictionary *candidate = [stack objectAtIndex:frameIndex];
        if ([candidate objectForKey:@"progress"] == self)
        {
            NSMutableDictionary *frame = [candidate retain];
            [stack removeObjectAtIndex:frameIndex];
            int64_t pending = [[frame objectForKey:@"pending"] longLongValue];
            NSArray *children = [frame objectForKey:@"children"];
            NSUInteger childCount = [children count];
            if (childCount == 0)
            {
                @synchronized(self)
                {
                    _completedUnitCount += pending;
                }
            }
            else
            {
                int64_t share = pending / (int64_t)childCount;
                int64_t remainder = pending % (int64_t)childCount;
                for (NSUInteger i = 0; i < childCount; i++)
                {
                    NSProgress *child = [children objectAtIndex:i];
                    @synchronized(child)
                    {
                        child->_parentPendingUnitCount = share + (i + 1 == childCount ? remainder : 0);
                    }
                }
            }
            [frame release];
            return;
        }
    }
}

- (BOOL)isCancelled
{
    @synchronized(self) {
        return _cancelled;
    }
}

- (BOOL)isPaused
{
    @synchronized(self) {
        return _paused;
    }
}

- (BOOL)isCancellable
{
    @synchronized(self) {
        return _cancellable;
    }
}

- (void)setCancellable: (BOOL)cancellable
{
    @synchronized(self) {
        _cancellable = cancellable;
    }
}

- (BOOL)isPausable
{
    @synchronized(self) {
        return _pausable;
    }
}

- (void)setPausable: (BOOL)pausable
{
    @synchronized(self) {
        _pausable = pausable;
    }
}

- (int64_t)completedUnitCount
{
    @synchronized(self) {
        int64_t count = _completedUnitCount;
        for (NSProgress *child in _childProgresses)
        {
            if (child->_parentProgress == self && child->_parentPendingUnitCount != 0 && [child isFinished])
            {
                count += child->_parentPendingUnitCount;
            }
        }
        return count;
    }
}

- (void)setCompletedUnitCount: (int64_t)count
{
    @synchronized(self) {
        _completedUnitCount = count;
    }
}

- (double)fractionCompleted
{
    @synchronized(self)
    {
        if (_totalUnitCount <= 0 || _completedUnitCount < 0)
        {
            return 0.0;
        }

        double completed = (double)_completedUnitCount;
        for (NSProgress *child in _childProgresses)
        {
            if (child->_parentProgress == self && child->_parentPendingUnitCount != 0)
            {
                completed += (double)child->_parentPendingUnitCount * [child fractionCompleted];
            }
        }
        double fraction = completed / (double)_totalUnitCount;
        if (fraction < 0.0) return 0.0;
        if (fraction > 1.0) return 1.0;
        return fraction;
    }
}

- (BOOL)isFinished
{
    int64_t total = [self totalUnitCount];
    int64_t completed = [self completedUnitCount];
    if (total < 0 || completed < 0 || (total == 0 && completed == 0))
    {
        return NO;
    }
    return completed >= total;
}

- (int64_t)totalUnitCount
{
    @synchronized(self) {
        return _totalUnitCount;
    }
}

- (void)setTotalUnitCount: (int64_t)count
{
    @synchronized(self) {
        _totalUnitCount = count;
    }
}

- (void)cancel
{
    @synchronized(self) {
        if (!_cancellable || _cancelled) {
            return;
        }

        _cancelled = YES;
        if (_cancellationHandler) {
            _cancellationHandler();
        }
    }
}

- (void)pause
{
    @synchronized(self) {
        if (!_pausable || _paused) {
            return;
        }

        _paused = YES;
        if (_pausingHandler) {
            _pausingHandler();
        }
    }
}

- (void)resume
{
    @synchronized(self) {
        if (!_paused) {
            return;
        }

        _paused = NO;
        if (_resumingHandler) {
            _resumingHandler();
        }
    }
}

- (NSNumber *)estimatedTimeRemaining
{
    @synchronized(self) { return [_userInfo objectForKey:NSProgressEstimatedTimeRemainingKey]; }
}

- (void)setEstimatedTimeRemaining:(NSNumber *)estimatedTimeRemaining
{
    [self setUserInfoObject:estimatedTimeRemaining forKey:NSProgressEstimatedTimeRemainingKey];
}

- (NSNumber *)throughput
{
    @synchronized(self) { return [_userInfo objectForKey:NSProgressThroughputKey]; }
}

- (void)setThroughput:(NSNumber *)throughput
{
    [self setUserInfoObject:throughput forKey:NSProgressThroughputKey];
}

- (NSNumber *)fileCompletedCount
{
    @synchronized(self) { return [_userInfo objectForKey:NSProgressFileCompletedCountKey]; }
}

- (void)setFileCompletedCount:(NSNumber *)fileCompletedCount
{
    [self setUserInfoObject:fileCompletedCount forKey:NSProgressFileCompletedCountKey];
}

- (NSNumber *)fileTotalCount
{
    @synchronized(self) { return [_userInfo objectForKey:NSProgressFileTotalCountKey]; }
}

- (void)setFileTotalCount:(NSNumber *)fileTotalCount
{
    [self setUserInfoObject:fileTotalCount forKey:NSProgressFileTotalCountKey];
}

- (NSURL *)fileURL
{
    @synchronized(self) { return [_userInfo objectForKey:NSProgressFileURLKey]; }
}

- (void)setFileURL:(NSURL *)fileURL
{
    [self setUserInfoObject:fileURL forKey:NSProgressFileURLKey];
}

- (NSString *)kind
{
    @synchronized(self) { return _kind; }
}

- (void)setKind:(NSString *)kind
{
    NSString *copy = [kind copy];
    @synchronized(self)
    {
        if (_kind != copy)
        {
            [_kind release];
            _kind = copy;
        }
        else
        {
            [copy release];
        }
    }
}

- (NSString *)localizedDescription
{
    @synchronized(self)
    {
        if (_localizedDescription)
        {
            return _localizedDescription;
        }
    }
    NSURL *url = [self fileURL];
    NSString *fileName = [url lastPathComponent];
    if ([fileName length] > 0)
    {
        return fileName;
    }
    return [NSString stringWithFormat:@"%lld of %lld", [self completedUnitCount], [self totalUnitCount]];
}

- (void)setLocalizedDescription:(NSString *)localizedDescription
{
    NSString *copy = [localizedDescription copy];
    @synchronized(self)
    {
        if (_localizedDescription != copy)
        {
            [_localizedDescription release];
            _localizedDescription = copy;
        }
        else
        {
            [copy release];
        }
    }
}

- (NSString *)localizedAdditionalDescription
{
    @synchronized(self)
    {
        if (_localizedAdditionalDescription)
        {
            return _localizedAdditionalDescription;
        }
    }
    NSNumber *completedFiles = [self fileCompletedCount];
    NSNumber *totalFiles = [self fileTotalCount];
    if (completedFiles && totalFiles)
    {
        return [NSString stringWithFormat:@"%@ of %@", completedFiles, totalFiles];
    }
    return [NSString stringWithFormat:@"%lld of %lld", [self completedUnitCount], [self totalUnitCount]];
}

- (void)setLocalizedAdditionalDescription:(NSString *)localizedAdditionalDescription
{
    NSString *copy = [localizedAdditionalDescription copy];
    @synchronized(self)
    {
        if (_localizedAdditionalDescription != copy)
        {
            [_localizedAdditionalDescription release];
            _localizedAdditionalDescription = copy;
        }
        else
        {
            [copy release];
        }
    }
}

- (void)setUserInfoObject:(id)object forKey:(NSString *)key
{
    @synchronized(self)
    {
        if (!_userInfo)
        {
            _userInfo = [[NSMutableDictionary alloc] init];
        }
        if (object)
        {
            [_userInfo setObject:object forKey:key];
        }
        else
        {
            [_userInfo removeObjectForKey:key];
        }
    }
}

- (NSDictionary<NSString *, id> *)userInfo
{
    @synchronized(self)
    {
        return _userInfo ? [NSDictionary dictionaryWithDictionary:_userInfo] : [NSDictionary dictionary];
    }
}

@end

@implementation _NSProgressWithRemoteParent

@synthesize sequence = _sequence;
@synthesize parentConnection = _parentConnection;

- (void)dealloc
{
    [_parentConnection release];
    [super dealloc];
}

@end

@implementation NSProgress (NSProgressUpdateOverXPC)

- (void)_receiveProgressMessage: (xpc_object_t)message forSequence: (NSUInteger)sequence
{

}

@end
