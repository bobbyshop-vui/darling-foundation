#import <Foundation/NSData+XcodeAdditions.h>
#import <objc/runtime.h>

@interface NSData (XcodeAdditionsPrivate)
- (id)initWithBytes:(void *)bytes length:(NSUInteger)length copy:(BOOL)shouldCopy deallocator:(void (^)(void *bytes, NSUInteger length))deallocator;
@end

@implementation NSData (XcodeAdditions)

- (instancetype)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length deallocator:(void (^)(void *bytes, NSUInteger length))deallocator
{
    // The concrete NSData classes keep the bytes and invoke the block when freed.
    if ([self respondsToSelector:@selector(initWithBytes:length:copy:deallocator:)])
    {
        return [self initWithBytes:bytes length:length copy:NO deallocator:deallocator];
    }

    // Any other subclass: take a private copy of the bytes and hand the
    // original buffer back to its owner right away.
    self = [self initWithBytes:bytes length:length];
    if (deallocator != nil)
    {
        deallocator(bytes, length);
    }
    return self;
}

// Swift's Data asks this before it copies the bytes out of an NSData: compact
// data keeps all of its bytes in one region.
- (BOOL)_isCompact
{
    NSUInteger length = [self length];
    __block BOOL compact = YES;
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        if (byteRange.length != length)
        {
            compact = NO;
        }
        *stop = YES;
    }];
    return compact;
}

@end
