#import <Foundation/NSLayoutConstraint.h>
#import <Foundation/NSException.h>

@interface NSLayoutAnchor (NSLayoutAnchorInternal)
- (instancetype)initWithItem:(id)item attribute:(NSLayoutAttribute)attribute name:(NSString *)name;
@end

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
    [_firstItem release];
    [_secondItem release];
    [_identifier release];
    [super dealloc];
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
    _active = active;
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
