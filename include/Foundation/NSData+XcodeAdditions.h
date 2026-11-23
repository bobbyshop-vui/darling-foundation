#import <Foundation/NSData.h>

/* initWithBytesNoCopy:length:deallocator: (macOS 10.9 SDK). */
@interface NSData (XcodeAdditions)

- (instancetype)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length deallocator:(void (^)(void *bytes, NSUInteger length))deallocator;

@end
