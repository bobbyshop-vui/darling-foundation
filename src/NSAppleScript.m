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

#import <Foundation/NSAppleScript.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSAppleEventDescriptor.h>

NSString *const NSAppleScriptErrorMessage = @"NSAppleScriptErrorMessage";
NSString *const NSAppleScriptErrorNumber = @"NSAppleScriptErrorNumber";
NSString *const NSAppleScriptErrorAppName = @"NSAppleScriptErrorAppName";
NSString *const NSAppleScriptErrorBriefMessage = @"NSAppleScriptErrorBriefMessage";
NSString *const NSAppleScriptErrorRange = @"NSAppleScriptErrorRange";

/*
 * Darling has no AppleScript (OSA) interpreter, so a script can be created and
 * its source read back, but compiling and executing report the failure through
 * the error dictionary the way a missing scripting component would.
 */
static const int NSAppleScriptUnavailableErrorNumber = -1751; // errOSAGeneralError

static void NSAppleScriptReportUnavailable(NSDictionary **errorInfo)
{
    if (errorInfo == NULL)
        return;

    NSString *message = @"AppleScript is not available on this system.";
    *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        message, NSAppleScriptErrorMessage,
        message, NSAppleScriptErrorBriefMessage,
        [NSNumber numberWithInt: NSAppleScriptUnavailableErrorNumber], NSAppleScriptErrorNumber,
        nil];
}

@implementation NSAppleScript

- (instancetype)initWithSource:(NSString *)source
{
    if ((self = [super init]) != nil)
        _appleScriptSource = [source copy];
    return self;
}

- (void)dealloc
{
    [_appleScriptSource release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[NSAppleScript allocWithZone: zone] initWithSource: _appleScriptSource];
}

- (NSString *)source
{
    return _appleScriptSource;
}

- (BOOL)compileAndReturnError:(NSDictionary **)errorInfo
{
    NSAppleScriptReportUnavailable(errorInfo);
    return NO;
}

- (NSAppleEventDescriptor *)executeAndReturnError:(NSDictionary **)errorInfo
{
    NSAppleScriptReportUnavailable(errorInfo);
    return nil;
}

@end
