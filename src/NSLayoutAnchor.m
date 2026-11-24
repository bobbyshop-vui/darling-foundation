#import <Foundation/NSLayoutAnchor.h>
#import <Foundation/NSLayoutConstraint.h>
#import <Foundation/NSException.h>

@interface NSLayoutAnchor (NSLayoutAnchorInternal)
- (NSLayoutAttribute)_layoutAttribute;
- (NSLayoutConstraint *)_constraintWithRelation:(NSLayoutRelation)relation toAnchor:(NSLayoutAnchor *)anchor multiplier:(CGFloat)multiplier constant:(CGFloat)constant;
- (NSLayoutConstraint *)_constraintWithRelation:(NSLayoutRelation)relation constant:(CGFloat)constant;
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

- (instancetype)initWithItem:(id)item attribute:(NSInteger)attribute name:(NSString *)name
{
    self = [super init];
    if (self != nil)
    {
        _item = item; // weak
        _attribute = attribute;
        _name = [name copy];
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (NSLayoutConstraint *)_constraintWithRelation:(NSLayoutRelation)relation toAnchor:(NSLayoutAnchor *)anchor multiplier:(CGFloat)multiplier constant:(CGFloat)constant
{
    if (anchor == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"A layout anchor is required to create a constraint"];
        return nil;
    }
    return [NSLayoutConstraint constraintWithItem:_item
                                        attribute:(NSLayoutAttribute)_attribute
                                        relatedBy:relation
                                           toItem:[anchor item]
                                        attribute:[anchor _layoutAttribute]
                                       multiplier:multiplier
                                         constant:constant];
}

- (NSLayoutConstraint *)_constraintWithRelation:(NSLayoutRelation)relation constant:(CGFloat)constant
{
    return [NSLayoutConstraint constraintWithItem:_item
                                        attribute:(NSLayoutAttribute)_attribute
                                        relatedBy:relation
                                           toItem:nil
                                        attribute:NSLayoutAttributeNotAnAttribute
                                       multiplier:1.0
                                         constant:constant];
}

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor *)anchor
{
    return [self _constraintWithRelation:NSLayoutRelationEqual toAnchor:anchor multiplier:1.0 constant:0.0];
}

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)constant
{
    return [self _constraintWithRelation:NSLayoutRelationEqual toAnchor:anchor multiplier:1.0 constant:constant];
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor
{
    return [self _constraintWithRelation:NSLayoutRelationGreaterThanOrEqual toAnchor:anchor multiplier:1.0 constant:0.0];
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)constant
{
    return [self _constraintWithRelation:NSLayoutRelationGreaterThanOrEqual toAnchor:anchor multiplier:1.0 constant:constant];
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor
{
    return [self _constraintWithRelation:NSLayoutRelationLessThanOrEqual toAnchor:anchor multiplier:1.0 constant:0.0];
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)constant
{
    return [self _constraintWithRelation:NSLayoutRelationLessThanOrEqual toAnchor:anchor multiplier:1.0 constant:constant];
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

@implementation NSLayoutXAxisAnchor

- (NSLayoutDimension *)anchorWithOffsetToAnchor:(NSLayoutXAxisAnchor *)otherAnchor
{
    return nil; // not supported
}

@end

@implementation NSLayoutYAxisAnchor

- (NSLayoutDimension *)anchorWithOffsetToAnchor:(NSLayoutYAxisAnchor *)otherAnchor
{
    return nil; // not supported
}

@end

@implementation NSLayoutDimension

- (NSLayoutConstraint *)constraintEqualToConstant:(CGFloat)constant
{
    return [self _constraintWithRelation:NSLayoutRelationEqual constant:constant];
}

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier
{
    return [self _constraintWithRelation:NSLayoutRelationEqual toAnchor:anchor multiplier:multiplier constant:0.0];
}

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier constant:(CGFloat)constant
{
    return [self _constraintWithRelation:NSLayoutRelationEqual toAnchor:anchor multiplier:multiplier constant:constant];
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToConstant:(CGFloat)constant
{
    return [self _constraintWithRelation:NSLayoutRelationGreaterThanOrEqual constant:constant];
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier
{
    return [self _constraintWithRelation:NSLayoutRelationGreaterThanOrEqual toAnchor:anchor multiplier:multiplier constant:0.0];
}

- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier constant:(CGFloat)constant
{
    return [self _constraintWithRelation:NSLayoutRelationGreaterThanOrEqual toAnchor:anchor multiplier:multiplier constant:constant];
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToConstant:(CGFloat)constant
{
    return [self _constraintWithRelation:NSLayoutRelationLessThanOrEqual constant:constant];
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier
{
    return [self _constraintWithRelation:NSLayoutRelationLessThanOrEqual toAnchor:anchor multiplier:multiplier constant:0.0];
}

- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier constant:(CGFloat)constant
{
    return [self _constraintWithRelation:NSLayoutRelationLessThanOrEqual toAnchor:anchor multiplier:multiplier constant:constant];
}

@end
