#import <Foundation/NSDimension.h>

@interface NSUnitLength : NSDimension

@property (class, readonly, copy) NSUnitLength *centimeters;
@property (class, readonly, copy) NSUnitLength *feet;
@property (class, readonly, copy) NSUnitLength *inches;
@property (class, readonly, copy) NSUnitLength *meters;
@property (class, readonly, copy) NSUnitLength *miles;
@property (class, readonly, copy) NSUnitLength *millimeters;
@property (class, readonly, copy) NSUnitLength *yards;

@end
