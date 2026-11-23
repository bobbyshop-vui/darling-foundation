#import <Foundation/NSDictionary.h>
#import <Foundation/NSSpellServer.h>
#import <Foundation/NSString.h>

NSString *const NSGrammarRange = @"NSGrammarRange";
NSString *const NSGrammarUserDescription = @"NSGrammarUserDescription";
NSString *const NSGrammarCorrections = @"NSGrammarCorrections";
#import <Foundation/NSDictionary.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSPort.h>

@implementation NSSpellServer

- (void) dealloc {
    [_languages release];
    [super dealloc];
}

- (id<NSSpellServerDelegate>) delegate {
    return _delegate;
}

- (void) setDelegate: (id<NSSpellServerDelegate>) delegate {
    _delegate = delegate;
}

- (BOOL) registerLanguage: (NSString *) language byVendor: (NSString *) vendor {
    if (language == nil)
        return NO;

    if (_languages == nil)
        _languages = [[NSMutableDictionary alloc] init];

    [_languages setObject: (vendor != nil ? vendor : @"") forKey: language];
    return YES;
}

- (BOOL) isWordInUserDictionaries: (NSString *) word
                    caseSensitive: (BOOL) caseSensitive
{
    // There is no user dictionary service; no word is ever learned.
    return NO;
}

- (void) run {
    NSRunLoop *loop = [NSRunLoop currentRunLoop];

    // Keep the run loop alive even when no sources are attached yet.
    [loop addPort: [NSPort port] forMode: NSDefaultRunLoopMode];

    while ([loop runMode: NSDefaultRunLoopMode
              beforeDate: [NSDate distantFuture]])
        ;
}

@end
