#import <Foundation/NSLayoutConstraint.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>

#import <objc/message.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>
#include <stdlib.h>

// Foundation cannot import AppKit; talk to views and layout guides dynamically.
static id layoutItemView(id item)
{
    if (item == nil)
        return nil;
    if ([item respondsToSelector:@selector(owningView)])
        return ((id (*)(id, SEL))objc_msgSend)(item, @selector(owningView));
    return item;
}

static id layoutItemSuperview(id view)
{
    if (view != nil && [view respondsToSelector:@selector(superview)])
        return ((id (*)(id, SEL))objc_msgSend)(view, @selector(superview));
    return nil;
}

static BOOL viewHasConstraint(id view, id constraint)
{
    if (![view respondsToSelector:@selector(constraints)])
        return NO;
    NSArray *list = ((id (*)(id, SEL))objc_msgSend)(view, @selector(constraints));
    return [list containsObject:constraint];
}

// The view a constraint belongs on: the item's view for one item, the nearest common
// ancestor (a view is its own ancestor) for two.
static id layoutHostView(NSLayoutConstraint *constraint)
{
    id first = layoutItemView([constraint firstItem]);
    id second = layoutItemView([constraint secondItem]);
    if (second == nil)
        return first;
    if (first == nil)
        return second;
    for (id a = first; a != nil; a = layoutItemSuperview(a))
    {
        for (id b = second; b != nil; b = layoutItemSuperview(b))
        {
            if (a == b)
                return a;
        }
    }
    return nil;
}

@implementation NSLayoutConstraint

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _multiplier = 1.0;
        _priority = 1000.0;
        _active = NO;
        _shouldBeArchived = NO;
    }
    return self;
}

- (void)dealloc
{
    _installedView = nil;
    [_firstItem release];
    [_secondItem release];
    [_identifier release];
    [super dealloc];
}

// Keys as written by Interface Builder into compiled nibs. Values equal to the defaults
// are omitted from the archive; the "V2" variants of the attributes and the constant carry
// the same values and take precedence when present.
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [self init];
    if (self == nil)
        return nil;

    if ([coder containsValueForKey:@"NSFirstItem"])
        _firstItem = [[coder decodeObjectForKey:@"NSFirstItem"] retain];
    if ([coder containsValueForKey:@"NSSecondItem"])
        _secondItem = [[coder decodeObjectForKey:@"NSSecondItem"] retain];

    if ([coder containsValueForKey:@"NSFirstAttributeV2"])
        _firstAttribute = (NSLayoutAttribute)[coder decodeIntegerForKey:@"NSFirstAttributeV2"];
    else if ([coder containsValueForKey:@"NSFirstAttribute"])
        _firstAttribute = (NSLayoutAttribute)[coder decodeIntegerForKey:@"NSFirstAttribute"];

    if ([coder containsValueForKey:@"NSSecondAttributeV2"])
        _secondAttribute = (NSLayoutAttribute)[coder decodeIntegerForKey:@"NSSecondAttributeV2"];
    else if ([coder containsValueForKey:@"NSSecondAttribute"])
        _secondAttribute = (NSLayoutAttribute)[coder decodeIntegerForKey:@"NSSecondAttribute"];

    if ([coder containsValueForKey:@"NSRelation"])
        _relation = (NSLayoutRelation)[coder decodeIntegerForKey:@"NSRelation"];
    if ([coder containsValueForKey:@"NSMultiplier"])
        _multiplier = [coder decodeDoubleForKey:@"NSMultiplier"];
    else if ([coder containsValueForKey:@"NSMultiplierV2"])
        _multiplier = [coder decodeDoubleForKey:@"NSMultiplierV2"];

    if ([coder containsValueForKey:@"NSConstantV2"])
        _constant = [coder decodeDoubleForKey:@"NSConstantV2"];
    else if ([coder containsValueForKey:@"NSConstant"])
        _constant = [coder decodeDoubleForKey:@"NSConstant"];

    if ([coder containsValueForKey:@"NSPriority"])
        _priority = (NSLayoutPriority)[coder decodeDoubleForKey:@"NSPriority"];
    else if ([coder containsValueForKey:@"NSPriorityV2"])
        _priority = (NSLayoutPriority)[coder decodeDoubleForKey:@"NSPriorityV2"];

    if ([coder containsValueForKey:@"NSLayoutIdentifier"])
        _identifier = [[coder decodeObjectForKey:@"NSLayoutIdentifier"] copy];

    _shouldBeArchived = [coder decodeBoolForKey:@"NSShouldBeArchived"];
    // NSSymbolicConstant only names the constant in Interface Builder; it has no effect on layout.
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if (_firstItem != nil)
        [coder encodeObject:_firstItem forKey:@"NSFirstItem"];
    if (_secondItem != nil)
        [coder encodeObject:_secondItem forKey:@"NSSecondItem"];
    [coder encodeInteger:_firstAttribute forKey:@"NSFirstAttribute"];
    [coder encodeInteger:_firstAttribute forKey:@"NSFirstAttributeV2"];
    [coder encodeInteger:_secondAttribute forKey:@"NSSecondAttribute"];
    [coder encodeInteger:_secondAttribute forKey:@"NSSecondAttributeV2"];
    [coder encodeInteger:_relation forKey:@"NSRelation"];
    [coder encodeDouble:_multiplier forKey:@"NSMultiplier"];
    [coder encodeDouble:_constant forKey:@"NSConstant"];
    [coder encodeDouble:_constant forKey:@"NSConstantV2"];
    [coder encodeDouble:_priority forKey:@"NSPriority"];
    if (_identifier != nil)
        [coder encodeObject:_identifier forKey:@"NSLayoutIdentifier"];
    [coder encodeBool:_shouldBeArchived forKey:@"NSShouldBeArchived"];
}

+ (NSLayoutConstraint *)constraintWithItem:(id)firstItem attribute:(NSLayoutAttribute)firstAttribute relatedBy:(NSLayoutRelation)relation toItem:(id)secondItem attribute:(NSLayoutAttribute)secondAttribute multiplier:(CGFloat)multiplier constant:(CGFloat)constant
{
    NSLayoutConstraint *constraint = [[[self alloc] init] autorelease];
    constraint->_firstItem = [firstItem retain];
    constraint->_firstAttribute = firstAttribute;
    constraint->_relation = relation;
    constraint->_secondItem = [secondItem retain];
    constraint->_secondAttribute = secondAttribute;
    constraint->_multiplier = multiplier;
    constraint->_constant = constant;
    return constraint;
}

// ---------------------------------------------------------------------------
// Visual format language
//
//   (H:|V:)? (| connection)? [view(sizes)] (connection [view(sizes)])* (connection |)?
//
// A connection is nothing (flush), "-" (standard spacing) or "-predicates-";
// predicates are a number or metric name, or "(" relation? (number | metric |
// view) (@ priority)? ("," ...)* ")". Darling does not solve constraints; this
// only builds them, as AppKit does.
// ---------------------------------------------------------------------------

static void VFLFail(NSString *format, NSUInteger position, NSString *reason)
{
    [NSException raise:NSInvalidArgumentException
                format:@"Unable to parse constraint format: %@\n%@\n%*s^", reason, format, (int)position, ""];
}

static BOOL VFLIsIdentifierStart(unichar c)
{
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

static BOOL VFLIsIdentifierChar(unichar c)
{
    return VFLIsIdentifierStart(c) || (c >= '0' && c <= '9');
}

typedef struct {
    NSString *format;
    unichar *chars;
    NSUInteger length;
    NSUInteger position;
    NSDictionary *metrics;
    NSDictionary *views;
} VFLParser;

static unichar VFLPeek(VFLParser *p)
{
    return p->position < p->length ? p->chars[p->position] : 0;
}

static NSString *VFLIdentifier(VFLParser *p)
{
    NSUInteger start = p->position;
    if (!VFLIsIdentifierStart(VFLPeek(p)))
        return nil;
    while (VFLIsIdentifierChar(VFLPeek(p)))
        p->position++;
    return [NSString stringWithCharacters:p->chars + start length:p->position - start];
}

// A number, or a metric name looked up in the metrics.
static NSNumber *VFLConstant(VFLParser *p)
{
    unichar c = VFLPeek(p);
    if ((c >= '0' && c <= '9') || c == '.' || c == '-')
    {
        NSUInteger start = p->position;
        p->position++;
        while (((c = VFLPeek(p)) >= '0' && c <= '9') || c == '.')
            p->position++;
        NSString *text = [NSString stringWithCharacters:p->chars + start length:p->position - start];
        return [NSNumber numberWithDouble:[text doubleValue]];
    }
    NSUInteger start = p->position;
    NSString *name = VFLIdentifier(p);
    if (name == nil)
        return nil;
    id metric = [p->metrics objectForKey:name];
    if (![metric isKindOfClass:[NSNumber class]])
    {
        p->position = start;
        return nil;
    }
    return metric;
}

// relation? (constant | view) (@priority)? -> dictionary
static NSDictionary *VFLPredicate(VFLParser *p, BOOL allowView)
{
    NSLayoutRelation relation = NSLayoutRelationEqual;
    if (p->position + 1 < p->length && p->chars[p->position + 1] == '=')
    {
        unichar c = VFLPeek(p);
        if (c == '=' || c == '>' || c == '<')
        {
            relation = c == '>' ? NSLayoutRelationGreaterThanOrEqual : c == '<' ? NSLayoutRelationLessThanOrEqual : NSLayoutRelationEqual;
            p->position += 2;
        }
    }

    NSMutableDictionary *predicate = [NSMutableDictionary dictionary];
    [predicate setObject:[NSNumber numberWithInteger:relation] forKey:@"relation"];

    NSUInteger start = p->position;
    NSNumber *constant = VFLConstant(p);
    if (constant != nil)
        [predicate setObject:constant forKey:@"constant"];
    else
    {
        NSString *name = VFLIdentifier(p);
        id view = name != nil ? [p->views objectForKey:name] : nil;
        if (view == nil || !allowView)
            VFLFail(p->format, start, name != nil ? [NSString stringWithFormat:@"%@ is not a key in the metrics or views dictionaries", name] : @"Expected a number, metric or view");
        [predicate setObject:view forKey:@"view"];
    }

    if (VFLPeek(p) == '@')
    {
        p->position++;
        NSUInteger priorityStart = p->position;
        NSNumber *priority = VFLConstant(p);
        if (priority == nil)
            VFLFail(p->format, priorityStart, @"Expected a priority");
        [predicate setObject:priority forKey:@"priority"];
    }
    return predicate;
}

// "(" predicate ("," predicate)* ")"
static NSArray *VFLPredicateList(VFLParser *p, BOOL allowView)
{
    NSMutableArray *predicates = [NSMutableArray array];
    p->position++; // (
    while (1)
    {
        [predicates addObject:VFLPredicate(p, allowView)];
        unichar c = VFLPeek(p);
        p->position++;
        if (c == ')')
            break;
        if (c != ',')
            VFLFail(p->format, p->position - 1, @"Expected ',' or ')'");
    }
    return predicates;
}

static void VFLAddConstraint(NSMutableArray *constraints, id item, NSLayoutAttribute attribute, id toItem, NSLayoutAttribute toAttribute, NSDictionary *predicate, CGFloat constant)
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:item
                                                                  attribute:attribute
                                                                  relatedBy:[[predicate objectForKey:@"relation"] integerValue]
                                                                     toItem:toItem
                                                                  attribute:toAttribute
                                                                 multiplier:1.0
                                                                   constant:constant];
    NSNumber *priority = [predicate objectForKey:@"priority"];
    if (priority != nil)
        [constraint setPriority:[priority floatValue]];
    [constraints addObject:constraint];
}

+ (NSArray *)constraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts metrics:(NSDictionary *)metrics views:(NSDictionary *)views
{
    // Spaces are not significant.
    NSString *compact = [[format componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
    NSUInteger length = [compact length];
    unichar *chars = malloc(sizeof(unichar) * (length + 1));
    [compact getCharacters:chars range:NSMakeRange(0, length)];
    VFLParser parser = { format, chars, length, 0, metrics, views };
    VFLParser *p = &parser;

    NSMutableArray *constraints = [NSMutableArray array];
    @try
    {
        BOOL vertical = NO;
        if (length >= 2 && chars[1] == ':' && (chars[0] == 'H' || chars[0] == 'V'))
        {
            vertical = chars[0] == 'V';
            p->position = 2;
        }

        NSLayoutAttribute leading, trailing, size;
        if (vertical)
        {
            leading = NSLayoutAttributeTop;
            trailing = NSLayoutAttributeBottom;
            size = NSLayoutAttributeHeight;
        }
        else
        {
            NSLayoutFormatOptions direction = opts & NSLayoutFormatDirectionMask;
            leading = direction == NSLayoutFormatDirectionLeftToRight ? NSLayoutAttributeLeft : direction == NSLayoutFormatDirectionRightToLeft ? NSLayoutAttributeRight : NSLayoutAttributeLeading;
            trailing = direction == NSLayoutFormatDirectionLeftToRight ? NSLayoutAttributeRight : direction == NSLayoutFormatDirectionRightToLeft ? NSLayoutAttributeLeft : NSLayoutAttributeTrailing;
            size = NSLayoutAttributeWidth;
        }

        // Items: views, or NSNull for the superview. Connections: the spacing
        // predicates between item i and i + 1.
        NSMutableArray *items = [NSMutableArray array];
        NSMutableArray *connections = [NSMutableArray array];
        NSMutableArray *sizes = [NSMutableArray array];

        if (VFLPeek(p) == '|')
        {
            [items addObject:[NSNull null]];
            [sizes addObject:[NSArray array]];
            p->position++;
        }

        while (p->position < length)
        {
            if ([items count] > 0)
            {
                // connection
                if (VFLPeek(p) == '-')
                {
                    p->position++;
                    unichar c = VFLPeek(p);
                    if (c == '[' || c == '|')
                        [connections addObject:@"standard"];
                    else
                    {
                        NSArray *predicates;
                        if (c == '(')
                            predicates = VFLPredicateList(p, NO);
                        else
                        {
                            NSUInteger start = p->position;
                            NSNumber *constant = VFLConstant(p);
                            if (constant == nil)
                                VFLFail(format, start, @"Expected a number or metric");
                            predicates = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:NSLayoutRelationEqual], @"relation", constant, @"constant", nil]];
                        }
                        if (VFLPeek(p) != '-')
                            VFLFail(format, p->position, @"Expected '-'");
                        p->position++;
                        [connections addObject:predicates];
                    }
                }
                else
                    [connections addObject:@"flush"];
            }

            unichar c = VFLPeek(p);
            if (c == '|')
            {
                if ([items count] == 0)
                    VFLFail(format, p->position, @"Expected a view");
                p->position++;
                [items addObject:[NSNull null]];
                [sizes addObject:[NSArray array]];
                if (p->position != length)
                    VFLFail(format, p->position, @"Expected the end of the format after '|'");
                break;
            }
            if (c != '[')
                VFLFail(format, p->position, @"Expected '['");
            p->position++;
            NSUInteger nameStart = p->position;
            NSString *name = VFLIdentifier(p);
            id view = name != nil ? [views objectForKey:name] : nil;
            if (view == nil)
                VFLFail(format, nameStart, name != nil ? [NSString stringWithFormat:@"%@ is not a key in the views dictionary", name] : @"Expected a view name");
            NSArray *viewSizes = [NSArray array];
            if (VFLPeek(p) == '(')
                viewSizes = VFLPredicateList(p, YES);
            if (VFLPeek(p) != ']')
                VFLFail(format, p->position, @"Expected ']'");
            p->position++;
            [items addObject:view];
            [sizes addObject:viewSizes];
        }

        id superview = nil;
        for (id item in items)
        {
            if (item != [NSNull null])
            {
                superview = layoutItemSuperview(item);
                break;
            }
        }

        NSMutableArray *viewsInOrder = [NSMutableArray array];
        for (NSUInteger i = 0; i < [items count]; i++)
        {
            id item = [items objectAtIndex:i];
            if (item == [NSNull null])
            {
                if (superview == nil)
                    VFLFail(format, 0, @"Unable to interpret '|' character, because the related view doesn't have a superview");
                continue;
            }
            [viewsInOrder addObject:item];
            for (NSDictionary *predicate in [sizes objectAtIndex:i])
            {
                id other = [predicate objectForKey:@"view"];
                if (other != nil)
                    VFLAddConstraint(constraints, item, size, other, size, predicate, 0);
                else
                    VFLAddConstraint(constraints, item, size, nil, NSLayoutAttributeNotAnAttribute, predicate, [[predicate objectForKey:@"constant"] doubleValue]);
            }
        }

        for (NSUInteger i = 0; i < [connections count]; i++)
        {
            id from = [items objectAtIndex:i];
            id to = [items objectAtIndex:i + 1];
            BOOL fromSuperview = from == [NSNull null], toSuperview = to == [NSNull null];
            id connection = [connections objectAtIndex:i];
            NSArray *predicates;
            if ([connection isEqual:@"flush"] || [connection isEqual:@"standard"])
            {
                CGFloat spacing = [connection isEqual:@"flush"] ? 0 : (fromSuperview || toSuperview) ? 20 : 8;
                predicates = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:NSLayoutRelationEqual], @"relation", [NSNumber numberWithDouble:spacing], @"constant", nil]];
            }
            else
                predicates = connection;

            for (NSDictionary *predicate in predicates)
            {
                CGFloat constant = [[predicate objectForKey:@"constant"] doubleValue];
                if (fromSuperview)
                    VFLAddConstraint(constraints, to, leading, superview, leading, predicate, constant);
                else if (toSuperview)
                    VFLAddConstraint(constraints, superview, trailing, from, trailing, predicate, constant);
                else
                    VFLAddConstraint(constraints, to, leading, from, trailing, predicate, constant);
            }
        }

        NSLayoutFormatOptions alignment = opts & NSLayoutFormatAlignmentMask;
        for (NSLayoutAttribute attribute = NSLayoutAttributeLeft; attribute <= NSLayoutAttributeFirstBaseline; attribute++)
        {
            if (!(alignment & (1 << attribute)))
                continue;
            for (NSUInteger i = 1; i < [viewsInOrder count]; i++)
            {
                NSDictionary *equal = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NSLayoutRelationEqual] forKey:@"relation"];
                VFLAddConstraint(constraints, [viewsInOrder objectAtIndex:i], attribute, [viewsInOrder objectAtIndex:i - 1], attribute, equal, 0);
            }
        }
    }
    @finally
    {
        free(chars);
    }
    return constraints;
}

+ (void)activateConstraints:(NSArray *)constraints
{
    for (NSLayoutConstraint *constraint in constraints)
    {
        [constraint setActive:YES];
    }
}

+ (void)deactivateConstraints:(NSArray *)constraints
{
    for (NSLayoutConstraint *constraint in constraints)
    {
        [constraint setActive:NO];
    }
}

- (CGFloat)constant
{
    return _constant;
}

- (NSLayoutAnchor *)firstAnchor
{
    return [[[NSLayoutAnchor alloc] initWithItem:_firstItem attribute:_firstAttribute name:nil] autorelease];
}

- (NSLayoutAttribute)firstAttribute
{
    return _firstAttribute;
}

- (id)firstItem
{
    return _firstItem;
}

- (NSString *)identifier
{
    return _identifier;
}

- (BOOL)isActive
{
    if (_installedView != nil)
        return viewHasConstraint(_installedView, self);
    return _active;
}

- (CGFloat)multiplier
{
    return _multiplier;
}

- (NSLayoutPriority)priority
{
    return _priority;
}

- (NSLayoutRelation)relation
{
    return _relation;
}

- (NSLayoutAnchor *)secondAnchor
{
    if (_secondItem == nil || _secondAttribute == NSLayoutAttributeNotAnAttribute)
    {
        return nil;
    }
    return [[[NSLayoutAnchor alloc] initWithItem:_secondItem attribute:_secondAttribute name:nil] autorelease];
}

- (NSLayoutAttribute)secondAttribute
{
    return _secondAttribute;
}

- (id)secondItem
{
    return _secondItem;
}

- (void)setActive:(BOOL)active
{
    if (active)
    {
        id host = layoutHostView(self);
        if (host != nil && [host respondsToSelector:@selector(addConstraint:)])
        {
            if (!viewHasConstraint(host, self))
                ((void (*)(id, SEL, id))objc_msgSend)(host, @selector(addConstraint:), self);
            _installedView = host;
            _active = YES;
        }
        else
        {
            // No view to install on yet; remember the request.
            _active = YES;
        }
    }
    else
    {
        id host = _installedView ?: layoutHostView(self);
        if (host != nil && [host respondsToSelector:@selector(removeConstraint:)] && viewHasConstraint(host, self))
            ((void (*)(id, SEL, id))objc_msgSend)(host, @selector(removeConstraint:), self);
        _installedView = nil;
        _active = NO;
    }
}

- (void)setConstant:(CGFloat)constant
{
    _constant = constant;
}

- (void)setIdentifier:(NSString *)identifier
{
    if (_identifier != identifier)
    {
        [_identifier release];
        _identifier = [identifier copy];
    }
}

- (void)setPriority:(NSLayoutPriority)priority
{
    _priority = priority;
}

- (void)setShouldBeArchived:(BOOL)shouldBeArchived
{
    _shouldBeArchived = shouldBeArchived;
}

- (BOOL)shouldBeArchived
{
    return _shouldBeArchived;
}

@end
