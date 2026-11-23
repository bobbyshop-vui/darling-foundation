#import <Foundation/NSObject.h>
#import <Foundation/NSLayoutAnchor.h>
#import <Foundation/NSGeometry.h>

typedef NSInteger NSLayoutRelation;
enum {
    NSLayoutRelationLessThanOrEqual = -1,
    NSLayoutRelationEqual = 0,
    NSLayoutRelationGreaterThanOrEqual = 1,
};

typedef NSInteger NSLayoutAttribute;
enum {
    NSLayoutAttributeNotAnAttribute = 0,
    NSLayoutAttributeLeft = 1,
    NSLayoutAttributeRight,
    NSLayoutAttributeTop,
    NSLayoutAttributeBottom,
    NSLayoutAttributeLeading,
    NSLayoutAttributeTrailing,
    NSLayoutAttributeWidth,
    NSLayoutAttributeHeight,
    NSLayoutAttributeCenterX,
    NSLayoutAttributeCenterY,
    NSLayoutAttributeLastBaseline,
    NSLayoutAttributeBaseline = NSLayoutAttributeLastBaseline,
    NSLayoutAttributeFirstBaseline,
};

typedef float NSLayoutPriority;

@interface NSLayoutConstraint : NSObject
{
@private
    id _firstItem;
    id _secondItem;
    NSString *_identifier;
    NSLayoutAttribute _firstAttribute;
    NSLayoutAttribute _secondAttribute;
    NSLayoutRelation _relation;
    CGFloat _multiplier;
    CGFloat _constant;
    NSLayoutPriority _priority;
    BOOL _active;
    BOOL _shouldBeArchived;
}

+ (void)activateConstraints:(NSArray *)constraints;
+ (NSLayoutConstraint *)constraintWithItem:(id)firstItem attribute:(NSLayoutAttribute)firstAttribute relatedBy:(NSLayoutRelation)relation toItem:(id)secondItem attribute:(NSLayoutAttribute)secondAttribute multiplier:(CGFloat)multiplier constant:(CGFloat)constant;
+ (void)deactivateConstraints:(NSArray *)constraints;

- (CGFloat)constant;
- (NSLayoutAnchor *)firstAnchor;
- (NSLayoutAttribute)firstAttribute;
- (id)firstItem;
- (NSString *)identifier;
- (BOOL)isActive;
- (CGFloat)multiplier;
- (NSLayoutPriority)priority;
- (NSLayoutRelation)relation;
- (NSLayoutAnchor *)secondAnchor;
- (NSLayoutAttribute)secondAttribute;
- (id)secondItem;
- (void)setActive:(BOOL)active;
- (void)setConstant:(CGFloat)constant;
- (void)setIdentifier:(NSString *)identifier;
- (void)setPriority:(NSLayoutPriority)priority;
- (void)setShouldBeArchived:(BOOL)shouldBeArchived;
- (BOOL)shouldBeArchived;

@end
