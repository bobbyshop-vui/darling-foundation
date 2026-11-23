#import <Foundation/NSLayoutAnchor.h>
#import <Foundation/NSLayoutConstraint.h>
#import <Foundation/NSException.h>

@interface NSLayoutAnchor (NSLayoutAnchorInternal)
- (instancetype)initWithItem:(id)item attribute:(NSLayoutAttribute)attribute name:(NSString *)name;
- (NSLayoutAttribute)_layoutAttribute;
@end

static NSString *nameForLayoutAttribute(NSLayoutAttribute attribute)
{
    switch (attribute)
    {
        case NSLayoutAttributeLeft: return @"left";
        case NSLayoutAttributeRight: return @"right";
        case NSLayoutAttributeTop: return @"top";
        case NSLayoutAttributeBottom: return @"bottom";
        case NSLayoutAttributeLeading: return @"leading";
        case NSLayoutAttributeTrailing: return @"trailing";
        case NSLayoutAttributeWidth: return @"width";
        case NSLayoutAttributeHeight: return @"height";
        case NSLayoutAttributeCenterX: return @"centerX";
        case NSLayoutAttributeCenterY: return @"centerY";
        case NSLayoutAttributeLastBaseline: return @"lastBaseline";
        case NSLayoutAttributeFirstBaseline: return @"firstBaseline";
        default: return @"anchor";
    }
}

@implementation NSLayoutAnchor

- (instancetype)init
{
    return [self initWithItem:nil attribute:NSLayoutAttributeNotAnAttribute name:nil];
}

- (instancetype)initWithItem:(id)item attribute:(NSLayoutAttribute)attribute name:(NSString *)name
{
    self = [super init];
    if (self != nil)
    {
        _item = [item retain];
        _attribute = attribute;
        _name = [name copy];
    }
    return self;
}

- (void)dealloc
{
    [_item release];
    [_name release];
    [super dealloc];
}

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)constant
{
    if (anchor == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"A layout anchor is required to create a constraint"];
        return nil;
    }
    return [NSLayoutConstraint constraintWithItem:_item
                                     attribute:(NSLayoutAttribute)_attribute
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:[anchor item]
                                       attribute:[anchor _layoutAttribute]
                                      multiplier:1.0
                                        constant:constant];
}

- (BOOL)hasAmbiguousLayout
{
    if ([_item respondsToSelector:@selector(hasAmbiguousLayout)])
    {
        return [_item hasAmbiguousLayout];
    }
    return NO;
}

- (id)item
{
    return _item;
}

- (NSString *)name
{
    return _name ?: nameForLayoutAttribute((NSLayoutAttribute)_attribute);
}

- (NSLayoutAttribute)_layoutAttribute
{
    return (NSLayoutAttribute)_attribute;
}

@end

@implementation NSLayoutDimension

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier
{
    if (anchor == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"A dimension anchor is required to create a constraint"];
        return nil;
    }
    return [NSLayoutConstraint constraintWithItem:[self item]
                                     attribute:[self _layoutAttribute]
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:[anchor item]
                                       attribute:[anchor _layoutAttribute]
                                      multiplier:multiplier
                                        constant:0.0];
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier
{
    if (anchor == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"A dimension anchor is required to create a constraint"];
        return nil;
    }
    return [NSLayoutConstraint constraintWithItem:[self item]
                                     attribute:[self _layoutAttribute]
                                      relatedBy:NSLayoutRelationGreaterThanOrEqual
                                         toItem:[anchor item]
                                       attribute:[anchor _layoutAttribute]
                                      multiplier:multiplier
                                        constant:0.0];
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToConstant:(CGFloat)constant
{
    return [NSLayoutConstraint constraintWithItem:[self item]
                                     attribute:[self _layoutAttribute]
                                      relatedBy:NSLayoutRelationGreaterThanOrEqual
                                         toItem:nil
                                       attribute:NSLayoutAttributeNotAnAttribute
                                      multiplier:1.0
                                        constant:constant];
}

@end
