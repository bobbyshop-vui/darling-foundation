/*
 This file is part of Darling.

 Copyright (C) 2025 Darling Developers

 Darling is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Darling is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Darling.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>

@class NSLayoutConstraint;
@class NSLayoutDimension;

@interface NSLayoutAnchor : NSObject
{
@protected
    id _item; // not retained: the item owns its anchors
    NSString *_name;
    NSInteger _attribute;
}

- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor *)anchor;
- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor;
- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor;
- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)constant;
- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)constant;
- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(CGFloat)constant;
- (BOOL)hasAmbiguousLayout;
- (id)item;
- (NSString *)name;
@end

// Private: designated initializer, used by AppKit (NSView / NSLayoutGuide) to create anchors.
// The item is NOT retained. The attribute is an NSLayoutAttribute value.
@interface NSLayoutAnchor (NSLayoutAnchorPrivate)
- (instancetype)initWithItem:(id)item attribute:(NSInteger)attribute name:(NSString *)name;
@end

@interface NSLayoutXAxisAnchor : NSLayoutAnchor
- (NSLayoutDimension *)anchorWithOffsetToAnchor:(NSLayoutXAxisAnchor *)otherAnchor;
@end

@interface NSLayoutYAxisAnchor : NSLayoutAnchor
- (NSLayoutDimension *)anchorWithOffsetToAnchor:(NSLayoutYAxisAnchor *)otherAnchor;
@end

@interface NSLayoutDimension : NSLayoutAnchor
- (NSLayoutConstraint *)constraintEqualToConstant:(CGFloat)constant;
- (NSLayoutConstraint *)constraintGreaterThanOrEqualToConstant:(CGFloat)constant;
- (NSLayoutConstraint *)constraintLessThanOrEqualToConstant:(CGFloat)constant;
- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier;
- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier;
- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier;
- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier constant:(CGFloat)constant;
- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier constant:(CGFloat)constant;
- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutDimension *)anchor multiplier:(CGFloat)multiplier constant:(CGFloat)constant;
@end
