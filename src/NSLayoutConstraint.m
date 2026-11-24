#import <Foundation/NSLayoutConstraint.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>

#import <objc/message.h>

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
