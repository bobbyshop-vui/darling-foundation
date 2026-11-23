#import <Foundation/NSURLComponents.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>

// Accessors NSURLQueryItem exposes in the SDK
@interface NSURLQueryItem (NSURLComponentsAccess)
- (instancetype)initWithName:(NSString *)name value:(NSString *)value;
+ (instancetype)queryItemWithName:(NSString *)name value:(NSString *)value;
- (NSString *)name;
- (NSString *)value;
@end

typedef enum {
    kCompUser, kCompPassword, kCompHost, kCompPath, kCompQuery, kCompFragment,
    kCompQueryItemName, kCompQueryItemValue
} NSURLCompKind;

static BOOL isUnreserved(unichar c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') ||
           c == '-' || c == '.' || c == '_' || c == '~';
}

static BOOL isSubDelim(unichar c) {
    return c != 0 && strchr("!$&'()*+,;=", (int)c) != NULL;
}

static BOOL isAllowed(unichar c, NSURLCompKind kind) {
    if (isUnreserved(c)) {
        return YES;
    }
    switch (kind) {
        case kCompUser:
        case kCompPassword:
            return isSubDelim(c);
        case kCompHost:
            return isSubDelim(c);
        case kCompPath:
            return isSubDelim(c) || c == ':' || c == '@' || c == '/';
        case kCompQuery:
        case kCompFragment:
            return isSubDelim(c) || c == ':' || c == '@' || c == '/' || c == '?';
        case kCompQueryItemName:
            return c != '&' && c != '=' && (isSubDelim(c) || c == ':' || c == '@' || c == '/' || c == '?');
        case kCompQueryItemValue:
            return c != '&' && (isSubDelim(c) || c == ':' || c == '@' || c == '/' || c == '?');
    }
    return NO;
}

static BOOL isHex(unichar c) {
    return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

static NSString *encodeComponent(NSString *s, NSURLCompKind kind) {
    if (s == nil) {
        return nil;
    }
    BOOL ipLiteral = (kind == kCompHost && [s hasPrefix:@"["]);
    NSMutableString *out = [NSMutableString stringWithCapacity:[s length]];
    NSUInteger len = [s length];
    NSUInteger i = 0;
    while (i < len) {
        unichar c = [s characterAtIndex:i];
        if (isAllowed(c, kind) || (ipLiteral && (c == '[' || c == ']' || c == ':'))) {
            [out appendFormat:@"%C", c];
            i++;
            continue;
        }
        NSUInteger n = 1;
        if (c >= 0xD800 && c < 0xDC00 && i + 1 < len) {
            n = 2;
        }
        NSData *d = [[s substringWithRange:NSMakeRange(i, n)] dataUsingEncoding:NSUTF8StringEncoding];
        const unsigned char *b = [d bytes];
        for (NSUInteger j = 0; j < [d length]; j++) {
            [out appendFormat:@"%%%02X", b[j]];
        }
        i += n;
    }
    return out;
}

static NSString *decodeComponent(NSString *s) {
    if (s == nil) {
        return nil;
    }
    NSString *d = [s stringByRemovingPercentEncoding];
    return d != nil ? d : s;
}

// YES if s is made only of characters allowed for the component plus well formed %XX escapes.
static BOOL isValidEncoded(NSString *s, NSURLCompKind kind) {
    NSUInteger len = [s length];
    BOOL ipLiteral = (kind == kCompHost && [s hasPrefix:@"["]);
    for (NSUInteger i = 0; i < len; i++) {
        unichar c = [s characterAtIndex:i];
        if (c == '%') {
            if (i + 2 >= len) {
                return NO;
            }
            if (!isHex([s characterAtIndex:i + 1]) || !isHex([s characterAtIndex:i + 2])) {
                return NO;
            }
            i += 2;
        } else if (!isAllowed(c, kind) && !(ipLiteral && (c == '[' || c == ']' || c == ':'))) {
            return NO;
        }
    }
    return YES;
}

static BOOL isValidScheme(NSString *s) {
    NSUInteger len = [s length];
    if (len == 0) {
        return NO;
    }
    for (NSUInteger i = 0; i < len; i++) {
        unichar c = [s characterAtIndex:i];
        BOOL alpha = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
        if (i == 0 ? !alpha : !(alpha || (c >= '0' && c <= '9') || c == '+' || c == '-' || c == '.')) {
            return NO;
        }
    }
    return YES;
}

static void raiseInvalid(NSString *what) {
    [NSException raise:NSInvalidArgumentException format:@"invalid characters in URL %@", what];
}

static NSString *checkedEncoded(NSString *s, NSURLCompKind kind, NSString *what) {
    if (s != nil && !isValidEncoded(s, kind)) {
        raiseInvalid(what);
    }
    return s;
}

@implementation NSURLComponents

- (instancetype)init {
    self = [super init];
    if (self) {
        _path = [@"" copy];
    }
    return self;
}

- (instancetype)initWithString:(NSString *)URLString {
    if (URLString == nil) {
        [self release];
        return nil;
    }
    // reject anything that is not a legal URL character
    NSUInteger len = [URLString length];
    for (NSUInteger i = 0; i < len; i++) {
        unichar c = [URLString characterAtIndex:i];
        if (c == '%') {
            if (i + 2 >= len || !isHex([URLString characterAtIndex:i + 1]) || !isHex([URLString characterAtIndex:i + 2])) {
                [self release];
                return nil;
            }
            i += 2;
        } else if (!(isUnreserved(c) || isSubDelim(c) || (c != 0 && strchr(":/?#[]@", (int)c) != NULL))) {
            [self release];
            return nil;
        }
    }

    self = [self init];
    if (self == nil) {
        return nil;
    }

    NSString *rest = URLString;
    NSRange r = [rest rangeOfString:@"#"];
    if (r.location != NSNotFound) {
        _fragment = [[rest substringFromIndex:r.location + 1] copy];
        rest = [rest substringToIndex:r.location];
    }
    r = [rest rangeOfString:@"?"];
    if (r.location != NSNotFound) {
        _query = [[rest substringFromIndex:r.location + 1] copy];
        rest = [rest substringToIndex:r.location];
    }

    // scheme
    NSRange colon = [rest rangeOfString:@":"];
    NSRange slash = [rest rangeOfString:@"/"];
    if (colon.location != NSNotFound && (slash.location == NSNotFound || colon.location < slash.location)) {
        NSString *scheme = [rest substringToIndex:colon.location];
        if (isValidScheme(scheme)) {
            _scheme = [scheme copy];
            rest = [rest substringFromIndex:colon.location + 1];
        }
    }

    // authority
    if ([rest hasPrefix:@"//"]) {
        rest = [rest substringFromIndex:2];
        NSRange end = [rest rangeOfString:@"/"];
        NSString *authority = rest;
        if (end.location != NSNotFound) {
            authority = [rest substringToIndex:end.location];
            rest = [rest substringFromIndex:end.location];
        } else {
            rest = @"";
        }
        NSRange at = [authority rangeOfString:@"@" options:NSBackwardsSearch];
        if (at.location != NSNotFound) {
            NSString *userinfo = [authority substringToIndex:at.location];
            authority = [authority substringFromIndex:at.location + 1];
            NSRange c = [userinfo rangeOfString:@":"];
            if (c.location != NSNotFound) {
                _user = [[userinfo substringToIndex:c.location] copy];
                _password = [[userinfo substringFromIndex:c.location + 1] copy];
            } else {
                _user = [userinfo copy];
            }
        }
        NSString *portString = nil;
        NSString *host = authority;
        if ([authority hasPrefix:@"["]) {
            NSRange close = [authority rangeOfString:@"]"];
            if (close.location == NSNotFound) {
                [self release];
                return nil;
            }
            host = [authority substringToIndex:close.location + 1];
            NSString *tail = [authority substringFromIndex:close.location + 1];
            if ([tail hasPrefix:@":"]) {
                portString = [tail substringFromIndex:1];
            } else if ([tail length] > 0) {
                [self release];
                return nil;
            }
        } else {
            NSRange pc = [authority rangeOfString:@":" options:NSBackwardsSearch];
            if (pc.location != NSNotFound) {
                host = [authority substringToIndex:pc.location];
                portString = [authority substringFromIndex:pc.location + 1];
            }
        }
        _host = [host copy];
        if ([portString length] > 0) {
            long long p = 0;
            for (NSUInteger i = 0; i < [portString length]; i++) {
                unichar c = [portString characterAtIndex:i];
                if (c < '0' || c > '9' || p > 99999999) {
                    [self release];
                    return nil;
                }
                p = p * 10 + (c - '0');
            }
            _port = [[NSNumber alloc] initWithLongLong:p];
        }
    }

    [_path release];
    _path = [rest copy];
    return self;
}

+ (instancetype)componentsWithString:(NSString *)URLString {
    return [[[self alloc] initWithString:URLString] autorelease];
}

- (instancetype)initWithURL:(NSURL *)url resolvingAgainstBaseURL:(BOOL)resolve {
    if (url == nil) {
        [self release];
        return nil;
    }
    NSString *s = (resolve && [url baseURL] != nil) ? [url absoluteString] : [url relativeString];
    return [self initWithString:s];
}

+ (instancetype)componentsWithURL:(NSURL *)url resolvingAgainstBaseURL:(BOOL)resolve {
    return [[[self alloc] initWithURL:url resolvingAgainstBaseURL:resolve] autorelease];
}

- (void)dealloc {
    [_scheme release];
    [_user release];
    [_password release];
    [_host release];
    [_port release];
    [_path release];
    [_query release];
    [_fragment release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    NSURLComponents *c = [[[self class] allocWithZone:zone] init];
    c->_scheme = [_scheme copy];
    c->_user = [_user copy];
    c->_password = [_password copy];
    c->_host = [_host copy];
    c->_port = [_port copy];
    [c->_path release];
    c->_path = [_path copy];
    c->_query = [_query copy];
    c->_fragment = [_fragment copy];
    return c;
}

// Builds the URL string; ranges (if not NULL) receives 8 entries:
// scheme, user, password, host, port, path, query, fragment. Returns nil if the combination is invalid.
- (NSString *)_buildStringWithRanges:(NSRange *)ranges {
    NSRange none = NSMakeRange(NSNotFound, 0);
    NSRange rs[8];
    for (int i = 0; i < 8; i++) {
        rs[i] = none;
    }
    BOOL hasAuthority = (_user != nil || _password != nil || _host != nil || _port != nil);
    NSString *path = _path != nil ? _path : @"";
    if (hasAuthority && [path length] > 0 && ![path hasPrefix:@"/"]) {
        return nil;
    }
    if (!hasAuthority && [path hasPrefix:@"//"]) {
        return nil;
    }
    NSMutableString *s = [NSMutableString string];
    if (_scheme != nil) {
        rs[0] = NSMakeRange([s length], [_scheme length]);
        [s appendString:_scheme];
        [s appendString:@":"];
    }
    if (hasAuthority) {
        [s appendString:@"//"];
        if (_user != nil || _password != nil) {
            if (_user != nil) {
                rs[1] = NSMakeRange([s length], [_user length]);
                [s appendString:_user];
            }
            if (_password != nil) {
                [s appendString:@":"];
                rs[2] = NSMakeRange([s length], [_password length]);
                [s appendString:_password];
            }
            [s appendString:@"@"];
        }
        if (_host != nil) {
            rs[3] = NSMakeRange([s length], [_host length]);
            [s appendString:_host];
        }
        if (_port != nil) {
            [s appendString:@":"];
            NSString *p = [_port stringValue];
            rs[4] = NSMakeRange([s length], [p length]);
            [s appendString:p];
        }
    }
    rs[5] = NSMakeRange([s length], [path length]);
    [s appendString:path];
    if (_query != nil) {
        [s appendString:@"?"];
        rs[6] = NSMakeRange([s length], [_query length]);
        [s appendString:_query];
    }
    if (_fragment != nil) {
        [s appendString:@"#"];
        rs[7] = NSMakeRange([s length], [_fragment length]);
        [s appendString:_fragment];
    }
    if (ranges != NULL) {
        for (int i = 0; i < 8; i++) {
            ranges[i] = rs[i];
        }
    }
    return s;
}

- (NSRange)_rangeAtIndex:(int)i {
    NSRange rs[8];
    if ([self _buildStringWithRanges:rs] == nil) {
        return NSMakeRange(NSNotFound, 0);
    }
    return rs[i];
}

- (NSString *)string {
    return [self _buildStringWithRanges:NULL];
}

- (NSURL *)URL {
    return [self URLRelativeToURL:nil];
}

- (NSURL *)URLRelativeToURL:(NSURL *)baseURL {
    NSString *s = [self string];
    if (s == nil) {
        return nil;
    }
    return [NSURL URLWithString:s relativeToURL:baseURL];
}

- (NSString *)scheme {
    return [[_scheme copy] autorelease];
}

- (void)setScheme:(NSString *)scheme {
    if (scheme != nil && !isValidScheme(scheme)) {
        [NSException raise:NSInvalidArgumentException format:@"invalid URL scheme %@", scheme];
    }
    if (_scheme != scheme) {
        [_scheme release];
        _scheme = [scheme copy];
    }
}

#define PE_PROPERTY(Name, name, ivar, kind, whatString)                              \
- (NSString *)percentEncoded##Name { return [[ivar copy] autorelease]; }              \
- (void)setPercentEncoded##Name:(NSString *)value {                                   \
    checkedEncoded(value, kind, whatString);                                          \
    if (ivar != value) { [ivar release]; ivar = [value copy]; }                       \
}                                                                                     \
- (NSString *)name { return decodeComponent(ivar); }                                  \
- (void)set##Name:(NSString *)value {                                                 \
    NSString *e = encodeComponent(value, kind);                                       \
    if (ivar != e) { [ivar release]; ivar = [e copy]; }                               \
}

PE_PROPERTY(User, user, _user, kCompUser, @"user")
PE_PROPERTY(Password, password, _password, kCompPassword, @"password")
PE_PROPERTY(Host, host, _host, kCompHost, @"host")
PE_PROPERTY(Query, query, _query, kCompQuery, @"query")
PE_PROPERTY(Fragment, fragment, _fragment, kCompFragment, @"fragment")

- (NSString *)percentEncodedPath {
    return [[_path copy] autorelease];
}

- (void)setPercentEncodedPath:(NSString *)value {
    checkedEncoded(value, kCompPath, @"path");
    [_path release];
    _path = [(value != nil ? value : @"") copy];
}

- (NSString *)path {
    return decodeComponent(_path);
}

- (void)setPath:(NSString *)value {
    [_path release];
    _path = [(value != nil ? encodeComponent(value, kCompPath) : @"") copy];
}

- (NSNumber *)port {
    return [[_port copy] autorelease];
}

- (void)setPort:(NSNumber *)port {
    if (port != nil && [port longLongValue] < 0) {
        [NSException raise:NSInvalidArgumentException format:@"negative URL port %@", port];
    }
    if (_port != port) {
        [_port release];
        _port = [port copy];
    }
}

- (NSRange)rangeOfScheme { return [self _rangeAtIndex:0]; }
- (NSRange)rangeOfUser { return [self _rangeAtIndex:1]; }
- (NSRange)rangeOfPassword { return [self _rangeAtIndex:2]; }
- (NSRange)rangeOfHost { return [self _rangeAtIndex:3]; }
- (NSRange)rangeOfPort { return [self _rangeAtIndex:4]; }
- (NSRange)rangeOfPath { return [self _rangeAtIndex:5]; }
- (NSRange)rangeOfQuery { return [self _rangeAtIndex:6]; }
- (NSRange)rangeOfFragment { return [self _rangeAtIndex:7]; }

- (NSArray *)_queryItemsDecoding:(BOOL)decode {
    if (_query == nil) {
        return nil;
    }
    NSMutableArray *items = [NSMutableArray array];
    if ([_query length] == 0) {
        return items;
    }
    for (NSString *pair in [_query componentsSeparatedByString:@"&"]) {
        NSString *name = pair;
        NSString *value = nil;
        NSRange eq = [pair rangeOfString:@"="];
        if (eq.location != NSNotFound) {
            name = [pair substringToIndex:eq.location];
            value = [pair substringFromIndex:eq.location + 1];
        }
        if (decode) {
            name = decodeComponent(name);
            value = decodeComponent(value);
        }
        [items addObject:[NSURLQueryItem queryItemWithName:name value:value]];
    }
    return items;
}

- (NSArray *)queryItems {
    return [self _queryItemsDecoding:YES];
}

- (NSArray *)percentEncodedQueryItems {
    return [self _queryItemsDecoding:NO];
}

- (void)_setQueryItems:(NSArray *)items encoding:(BOOL)encode {
    NSString *q = nil;
    if (items != nil) {
        NSMutableString *s = [NSMutableString string];
        BOOL first = YES;
        for (NSURLQueryItem *item in items) {
            NSString *name = [item name];
            NSString *value = [item value];
            if (encode) {
                name = encodeComponent(name, kCompQueryItemName);
                value = encodeComponent(value, kCompQueryItemValue);
            } else {
                if (!isValidEncoded(name, kCompQueryItemName) ||
                    (value != nil && !isValidEncoded(value, kCompQueryItemValue))) {
                    raiseInvalid(@"query item");
                }
            }
            if (!first) {
                [s appendString:@"&"];
            }
            first = NO;
            [s appendString:name];
            if (value != nil) {
                [s appendString:@"="];
                [s appendString:value];
            }
        }
        q = s;
    }
    if (_query != q) {
        [_query release];
        _query = [q copy];
    }
}

- (void)setQueryItems:(NSArray *)items {
    [self _setQueryItems:items encoding:YES];
}

- (void)setPercentEncodedQueryItems:(NSArray *)items {
    [self _setQueryItems:items encoding:NO];
}

@end
