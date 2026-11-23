/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSArray.h>
#import <Foundation/NSRaise.h>
#import <Foundation/NSString.h>
#import <Foundation/NSXMLDTDNode.h>
#import <Foundation/NSXMLDocument.h>
#import <Foundation/NSXMLElement.h>
#import <Foundation/NSXMLNode.h>

static NSString *stringByResolvingXMLEntities(NSString *string) {
    if (string == nil)
        return nil;
    NSMutableString *result = [NSMutableString stringWithCapacity: [string length]];
    NSUInteger length = [string length];
    NSUInteger index = 0;

    while (index < length) {
        if ([string characterAtIndex: index] != '&') {
            [result appendString: [string substringWithRange: NSMakeRange(index, 1)]];
            index++;
            continue;
        }

        NSUInteger end = index + 1;
        while (end < length && [string characterAtIndex: end] != ';')
            end++;
        if (end == length) {
            [result appendString: @"&"];
            index++;
            continue;
        }

        NSString *entity = [string substringWithRange:
                NSMakeRange(index + 1, end - index - 1)];
        NSString *replacement = nil;
        if ([entity isEqualToString: @"amp"])
            replacement = @"&";
        else if ([entity isEqualToString: @"lt"])
            replacement = @"<";
        else if ([entity isEqualToString: @"gt"])
            replacement = @">";
        else if ([entity isEqualToString: @"quot"])
            replacement = @"\"";
        else if ([entity isEqualToString: @"apos"])
            replacement = @"'";
        else if ([entity hasPrefix: @"#"]) {
            NSUInteger position = 1;
            NSUInteger base = 10;
            NSUInteger codePoint = 0;
            BOOL valid = YES;

            if (position < [entity length] &&
                ([entity characterAtIndex: position] == 'x' ||
                 [entity characterAtIndex: position] == 'X')) {
                base = 16;
                position++;
            }
            if (position == [entity length])
                valid = NO;
            for (; valid && position < [entity length]; position++) {
                unichar digit = [entity characterAtIndex: position];
                NSUInteger value;
                if (digit >= '0' && digit <= '9')
                    value = digit - '0';
                else if (base == 16 && digit >= 'a' && digit <= 'f')
                    value = digit - 'a' + 10;
                else if (base == 16 && digit >= 'A' && digit <= 'F')
                    value = digit - 'A' + 10;
                else {
                    valid = NO;
                    break;
                }
                if (value >= base || codePoint > (0x10ffff - value) / base) {
                    valid = NO;
                    break;
                }
                codePoint = codePoint * base + value;
            }

            if (valid && codePoint != 0 && codePoint <= 0x10ffff &&
                !(codePoint >= 0xd800 && codePoint <= 0xdfff)) {
                unichar characters[2];
                NSUInteger characterCount;
                if (codePoint <= 0xffff) {
                    characters[0] = (unichar) codePoint;
                    characterCount = 1;
                } else {
                    codePoint -= 0x10000;
                    characters[0] = (unichar) (0xd800 + (codePoint >> 10));
                    characters[1] = (unichar) (0xdc00 + (codePoint & 0x3ff));
                    characterCount = 2;
                }
                replacement = [NSString stringWithCharacters: characters
                                                       length: characterCount];
            }
        }

        if (replacement != nil)
            [result appendString: replacement];
        else
            [result appendString: [string substringWithRange:
                    NSMakeRange(index, end - index + 1)]];
        index = end + 1;
    }

    return result;
}

static NSString *XPathNodeTest(NSXMLNode *node) {
    switch ([node kind]) {
    case NSXMLElementKind:
        return [node name] != nil ? [node name] : @"*";
    case NSXMLTextKind:
        return @"text()";
    case NSXMLCommentKind:
        return @"comment()";
    case NSXMLProcessingInstructionKind:
        return [node name] != nil
                       ? [NSString stringWithFormat: @"processing-instruction('%@')",
                                                    [node name]]
                       : @"processing-instruction()";
    case NSXMLAttributeKind:
        return [NSString stringWithFormat: @"@%@", [node name]];
    default:
        return [node name] != nil ? [node name] : @"node()";
    }
}

@implementation NSXMLNode

+ document {
    return [[[NSXMLDocument alloc] init] autorelease];
}

+ documentWithRootElement: (NSXMLElement *) element {
    return [[[NSXMLDocument alloc] initWithRootElement: element] autorelease];
}

+ elementWithName: (NSString *) name {
    return [[[NSXMLElement alloc] initWithName: name] autorelease];
}

+ elementWithName: (NSString *) name
          children: (NSArray *) children
        attributes: (NSArray *) attributes
{
    NSXMLElement *result =
            [[[NSXMLElement alloc] initWithName: name] autorelease];

    [result setChildren: children];
    [result setAttributes: attributes];

    return result;
}

+ elementWithName: (NSString *) name stringValue: (NSString *) string {
    return [[[NSXMLElement alloc] initWithName: name
                                   stringValue: string] autorelease];
}

+ attributeWithName: (NSString *) name stringValue: (NSString *) string {
    NSXMLNode *result =
            [[[self alloc] initWithKind: NSXMLAttributeKind] autorelease];

    [result setName: name];
    [result setStringValue: string];

    return result;
}

+ attributeWithName: (NSString *) name
                URI: (NSString *) URI
       stringValue: (NSString *) string
{
    NSXMLNode *result = [self attributeWithName: name stringValue: string];
    [result setURI: URI];
    return result;
}

+ commentWithStringValue: (NSString *) string {
    NSXMLNode *result =
            [[[self alloc] initWithKind: NSXMLCommentKind] autorelease];

    [result setStringValue: string];

    return result;
}

+ textWithStringValue: (NSString *) string {
    NSXMLNode *result =
            [[[self alloc] initWithKind: NSXMLTextKind] autorelease];

    [result setStringValue: string];

    return result;
}

+ processingInstructionWithName: (NSString *) name
                    stringValue: (NSString *) string
{
    NSXMLNode *result = [[[self alloc]
            initWithKind: NSXMLProcessingInstructionKind] autorelease];

    [result setName: name];
    [result setStringValue: string];

    return result;
}

+ DTDNodeWithXMLString: (NSString *) string {
    return [[[NSXMLDTDNode alloc] initWithXMLString: string] autorelease];
}

+ namespaceWithName: (NSString *) name stringValue: (NSString *) string {
    NSXMLNode *result =
            [[[self alloc] initWithKind: NSXMLNamespaceKind] autorelease];

    [result setName: name];
    [result setStringValue: string];

    return result;
}

+ (NSXMLNode *) predefinedNamespaceForPrefix: (NSString *) prefix {
    NSUnimplementedMethod();
    return nil;
}

+ (NSString *) prefixForName: (NSString *) name {
    NSRange colon = [name rangeOfString: @":"];
    if (colon.location == NSNotFound || colon.location == 0)
        return nil;
    return [name substringToIndex: colon.location];
}

+ (NSString *) localNameForName: (NSString *) name {
    NSUnimplementedMethod();
    return nil;
}

- initWithKind: (NSXMLNodeKind) kind {
    return [self initWithKind: kind options: NSXMLNodeOptionsNone];
}

- initWithKind: (NSXMLNodeKind) kind options: (NSUInteger) options {
    _parent = nil;
    _children = [[NSMutableArray alloc] init];
    _index = 0;
    _kind = kind;
    _options = options;
    _name = nil;
    _URI = nil;
    _value = @""; // Behavior is empty string not null
    return self;
}

- (void) dealloc {
    _parent = nil;
    [_children release];
    [_name release];
    [_URI release];
    [_value release];
    [super dealloc];
}

- copyWithZone: (NSZone *) zone {
    NSXMLNode *copy = NSCopyObject(self, 0, zone);

    copy->_name = [_name copy];
    copy->_URI = [_URI copy];
    copy->_value = [_value copy];

    return copy;
}

- (NSUInteger) index {
    return _index;
}

- (NSXMLNodeKind) kind {
    return _kind;
}

- (NSUInteger) level {
    NSUInteger result = 0;
    NSXMLNode *ancestor = _parent;
    while (ancestor != nil) {
        result++;
        ancestor = [ancestor parent];
    }
    return result;
}

- (NSString *) localName {
    NSRange colon = [_name rangeOfString: @":"];
    if (colon.location == NSNotFound)
        return _name;
    return [_name substringFromIndex: NSMaxRange(colon)];
}

- (NSString *) name {
    return _name;
}

- (NSXMLNode *) nextNode {
    if ([_children count] != 0)
        return [_children objectAtIndex: 0];

    NSXMLNode *node = self;
    while (node->_parent != nil) {
        NSXMLNode *parent = node->_parent;
        NSUInteger index = [parent->_children indexOfObjectIdenticalTo: node];
        if (index != NSNotFound && index + 1 < [parent->_children count])
            return [parent->_children objectAtIndex: index + 1];
        node = parent;
    }
    return nil;
}

- (NSXMLNode *) nextSibling {
    if (_parent == nil)
        return nil;
    NSUInteger index = [_parent->_children indexOfObjectIdenticalTo: self];
    if (index == NSNotFound || index + 1 >= [_parent->_children count])
        return nil;
    return [_parent->_children objectAtIndex: index + 1];
}

- (NSString *) stringValue {
    return _value;
}

- (NSString *) URI {
    return _URI;
}

- objectValue {
    return _value;
}

- (NSXMLNode *) parent {
    return _parent;
}

- (NSString *) prefix {
    return [[self class] prefixForName: _name];
}

- (NSXMLNode *) previousNode {
    NSUnimplementedMethod();
    return nil;
}

- (NSXMLNode *) previousSibling {
    if (_parent == nil)
        return nil;
    NSUInteger index = [_parent->_children indexOfObjectIdenticalTo: self];
    if (index == NSNotFound || index == 0)
        return nil;
    return [_parent->_children objectAtIndex: index - 1];
}

- (NSXMLDocument *) rootDocument {
    NSUnimplementedMethod();
    return nil;
}

- (NSUInteger) childCount {
    return [_children count];
}

- (NSArray *) children {
    return _children;
}

- (NSXMLNode *) childAtIndex: (NSUInteger) index {
    return [_children objectAtIndex: index];
}

- (void) setName: (NSString *) name {
    name = [name copy];
    [_name release];
    _name = name;
}

- (void) setURI: (NSString *) URI {
    URI = [URI copy];
    [_URI release];
    _URI = URI;
}

- (void) setObjectValue: object {
    object = [object retain];
    [_value release];
    _value = object;
}

- (void) setStringValue: (NSString *) string {
    string = [string copy];
    [_value release];
    _value = string;
}

- (void) setStringValue: (NSString *) string
        resolvingEntities: (BOOL) resolveEntities
{
    [self setStringValue: resolveEntities
                           ? stringByResolvingXMLEntities(string)
                           : string];
}

- (void) detach {
    //   [_parent removeChild:self];
    _parent = nil;
}

- (NSArray *) nodesForXPath: (NSString *) xpath error: (NSError **) error {
    NSMutableArray *result = [NSMutableArray array];
    NSRange range = [xpath rangeOfString: @"/"];

    if (range.location == NSNotFound) {

        for (NSXMLNode *node in _children) {

            if ([xpath isEqualToString: @"*"])
                [result addObject: node];

            if ([xpath isEqualToString: [node name]])
                [result addObject: node];
        }
    } else {
        NSString *firstComponent =
                [xpath substringWithRange: NSMakeRange(0, range.location)];
        NSString *remainder = [xpath substringFromIndex: NSMaxRange(range)];

        for (NSXMLNode *node in _children) {

            if ([firstComponent isEqualToString: @"*"])
                [result addObjectsFromArray: [node nodesForXPath: remainder
                                                           error: error]];

            if ([firstComponent isEqualToString: [node name]])
                [result addObjectsFromArray: [node nodesForXPath: remainder
                                                           error: error]];
        }
    }

    return result;
}

- (NSArray *) objectsForXQuery: (NSString *) xquery
                     constants: (NSDictionary *) constants
                         error: (NSError **) error
{
    NSUnimplementedMethod();
    return nil;
}

- (NSArray *) objectsForXQuery: (NSString *) xquery error: (NSError **) error {
    NSUnimplementedMethod();
    return nil;
}

- (NSString *) XMLString {
    return [self XMLStringWithOptions: 0];
}

- (NSString *) XMLStringWithOptions: (NSUInteger) options {
    NSMutableString *result = [NSMutableString string];

    switch ([self kind]) {

    case NSXMLInvalidKind:
        break;

    case NSXMLDocumentKind:
        // Handled in subclass
        break;

    case NSXMLElementKind:
        // Handled in subclass
        break;

    case NSXMLAttributeKind:
        [result appendString: [self name]];
        [result appendString: @"=\""];
        [result appendString: [self stringValue]];
        [result appendString: @"\""];
        break;

    case NSXMLNamespaceKind:
        break;

    case NSXMLProcessingInstructionKind:
        break;

    case NSXMLCommentKind:
        break;

    case NSXMLTextKind:
        break;

    case NSXMLDTDKind:
        break;

    case NSXMLEntityDeclarationKind:
        break;

    case NSXMLAttributeDeclarationKind:
        break;

    case NSXMLElementDeclarationKind:
        break;

    case NSXMLNotationDeclarationKind:
        break;
    }

    return result;
}

- (NSString *) XPath {
    if (_kind == NSXMLDocumentKind)
        return nil;

    NSMutableArray *components = [NSMutableArray array];
    NSXMLNode *node = self;
    while (node != nil && [node kind] != NSXMLDocumentKind) {
        NSString *test = XPathNodeTest(node);
        NSUInteger sameTypeCount = 0;
        NSUInteger matchingIndex = 0;
        NSArray *siblings = [[node parent] children];

        for (NSXMLNode *sibling in siblings) {
            if ([XPathNodeTest(sibling) isEqualToString: test]) {
                sameTypeCount++;
                if (sibling == node)
                    matchingIndex = sameTypeCount;
            }
        }

        if (sameTypeCount > 1 && matchingIndex != 0)
            test = [test stringByAppendingFormat: @"[%lu]",
                                                  (unsigned long) matchingIndex];
        [components insertObject: test atIndex: 0];
        node = [node parent];
    }

    return [components count] != 0
                   ? [components componentsJoinedByString: @"/"]
                   : nil;
}

- (NSString *) canonicalXMLStringPreservingComments: (BOOL) comments {
    NSUnimplementedMethod();
    return nil;
}

- (NSString *) description {
    return [self XMLString];
}

@end
