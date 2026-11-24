/*
 This file is part of Darling.

 Copyright (C) 2019 Lubos Dolezel

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

#import <Foundation/NSExtensionContext.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSError.h>

NSString * const NSExtensionItemsAndErrorsKey = @"NSExtensionItemsAndErrorsKey";

/* Undocumented */
NSString * const NSExtensionPointName = @"NSExtensionPointName";
/* End undocumented */

@implementation NSExtensionContext

// There is no extension host to deliver the cancellation to, so the error is retained
// for the lifetime of the context.
- (void)cancelRequestWithError:(NSError *)error
{
    if (error != _extensionCancellationError)
    {
        [_extensionCancellationError release];
        _extensionCancellationError = [error retain];
    }
}

- (void)dealloc
{
    [_extensionCancellationError release];
    [super dealloc];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [NSMethodSignature signatureWithObjCTypes: "v@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"Stub called: %@ in %@", NSStringFromSelector([anInvocation selector]), [self class]);
}

@end

// NSExtension is implemented in NSExtension.m.
