#import <Foundation/NSUserScriptTask.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSError.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSString.h>

@implementation NSUserScriptTask

- (instancetype)initWithURL:(NSURL *)url error:(NSError **)error
{
    if (error)
        *error = nil;

    BOOL isDirectory = NO;
    NSString *path = [url path];
    if (![url isFileURL] || ![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] || isDirectory) {
        if (error)
            *error = [NSError errorWithDomain:@"NSUserScriptTaskErrorDomain" code:1 userInfo:nil];
        [self release];
        return nil;
    }

    NSString *extension = [path pathExtension];
    BOOL isAppleScript = [extension caseInsensitiveCompare:@"scpt"] == NSOrderedSame ||
                         [extension caseInsensitiveCompare:@"applescript"] == NSOrderedSame;
    if (!isAppleScript) {
        if (error)
            *error = [NSError errorWithDomain:@"NSUserScriptTaskErrorDomain" code:2 userInfo:nil];
        [self release];
        return nil;
    }
    if ([self class] == [NSUserScriptTask class] && isAppleScript) {
        [self release];
        self = [[NSUserAppleScriptTask alloc] init];
        if (!self)
            return nil;
    }

    self = [super init];
    if (self)
        _scriptURL = [url copy];
    return self;
}

- (NSURL *)scriptURL
{
    return _scriptURL;
}

- (void)dealloc
{
    [_scriptURL release];
    [super dealloc];
}

@end

@implementation NSUserAppleScriptTask

@end
