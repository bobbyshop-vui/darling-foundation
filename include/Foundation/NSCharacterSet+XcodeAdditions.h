#import <Foundation/NSCharacterSet.h>

@interface NSCharacterSet (XcodeAdditions)

+ (NSCharacterSet *)URLUserAllowedCharacterSet;
+ (NSCharacterSet *)URLPasswordAllowedCharacterSet;
+ (NSCharacterSet *)URLHostAllowedCharacterSet;
+ (NSCharacterSet *)URLPathAllowedCharacterSet;
+ (NSCharacterSet *)URLQueryAllowedCharacterSet;
+ (NSCharacterSet *)URLFragmentAllowedCharacterSet;

@end
