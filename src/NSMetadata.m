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

#import <Foundation/NSMetadata.h>
#import <Foundation/NSMethodSignature.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSOperation.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>

NSString * const NSMetadataQueryDidStartGatheringNotification = @"NSMetadataQueryDidStartGatheringNotification";
NSString * const NSMetadataQueryGatheringProgressNotification = @"NSMetadataQueryGatheringProgressNotification";
NSString * const NSMetadataQueryDidFinishGatheringNotification = @"NSMetadataQueryDidFinishGatheringNotification";
NSString * const NSMetadataQueryDidUpdateNotification = @"NSMetadataQueryDidUpdateNotification";
NSString * const NSMetadataQueryResultContentRelevanceAttribute = @"NSMetadataQueryResultContentRelevanceAttribute";
NSString * const NSMetadataQueryUbiquitousDocumentsScope = @"NSMetadataQueryUbiquitousDocumentsScope";
NSString * const NSMetadataQueryUbiquitousDataScope = @"NSMetadataQueryUbiquitousDataScope";
NSString * const NSMetadataItemFSNameKey = @"kMDItemFSName";
NSString * const NSMetadataItemDisplayNameKey = @"kMDItemDisplayName";
NSString * const NSMetadataItemURLKey = @"kMDItemURL";
NSString * const NSMetadataItemPathKey = @"kMDItemPath";
NSString * const NSMetadataItemFSSizeKey = @"kMDItemFSSize";
NSString * const NSMetadataItemFSCreationDateKey = @"kMDItemFSCreationDate";
NSString * const NSMetadataItemFSContentChangeDateKey = @"kMDItemFSContentChangeDate";
NSString * const NSMetadataItemIsUbiquitousKey = @"NSMetadataItemIsUbiquitousKey";
NSString * const NSMetadataUbiquitousItemHasUnresolvedConflictsKey = @"NSMetadataUbiquitousItemHasUnresolvedConflictsKey";
NSString * const NSMetadataUbiquitousItemIsDownloadedKey = @"NSMetadataUbiquitousItemIsDownloadedKey";
NSString * const NSMetadataUbiquitousItemIsDownloadingKey = @"NSMetadataUbiquitousItemIsDownloadingKey";
NSString * const NSMetadataUbiquitousItemIsUploadedKey = @"NSMetadataUbiquitousItemIsUploadedKey";
NSString * const NSMetadataUbiquitousItemIsUploadingKey = @"NSMetadataUbiquitousItemIsUploadingKey";
NSString * const NSMetadataUbiquitousItemPercentDownloadedKey = @"NSMetadataUbiquitousItemPercentDownloadedKey";
NSString * const NSMetadataUbiquitousItemPercentUploadedKey = @"NSMetadataUbiquitousItemPercentUploadedKey";
NSString * const NSMetadataQueryLocalComputerScope = @"kMDQueryScopeComputer";

@implementation NSMetadataQuery

- (void)dealloc
{
    [_operationQueue release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return self;
}

- (id <NSMetadataQueryDelegate>)delegate
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (NSOperationQueue *)operationQueue
{
    return _operationQueue;
}

- (void)setOperationQueue:(NSOperationQueue *)operationQueue
{
    if (_operationQueue != operationQueue)
    {
        [_operationQueue release];
        _operationQueue = [operationQueue retain];
    }
}

- (void)setDelegate:(id <NSMetadataQueryDelegate>)delegate
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (NSPredicate *)predicate
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (void)setPredicate:(NSPredicate *)predicate
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (NSArray *)sortDescriptors
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (void)setSortDescriptors:(NSArray *)descriptors
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (NSArray *)valueListAttributes
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (void)setValueListAttributes:(NSArray *)attrs
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (NSArray *)groupingAttributes
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (void)setGroupingAttributes:(NSArray *)attrs
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (NSTimeInterval)notificationBatchingInterval
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return 0;
}

- (void)setNotificationBatchingInterval:(NSTimeInterval)ti
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (NSArray *)searchScopes
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (void)setSearchScopes:(NSArray *)scopes
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (BOOL)startQuery
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return NO;
}

- (void)stopQuery
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (BOOL)isStarted
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return NO;
}

- (BOOL)isGathering
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return NO;
}

- (BOOL)isStopped
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return NO;
}

- (void)disableUpdates
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (void)enableUpdates
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
}

- (NSUInteger)resultCount
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return 0;
}

- (id)resultAtIndex:(NSUInteger)idx
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (NSArray *)results
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (NSUInteger)indexOfResult:(id)result
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return 0;
}

- (NSDictionary *)valueLists
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (NSArray *)groupedResults
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (id)valueOfAttribute:(NSString *)attrName forResultAtIndex:(NSUInteger)idx
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

@end

@implementation NSMetadataItem

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self != nil)
    {
        _url = [url retain];
    }
    return self;
}

- (void)dealloc
{
    [_url release];
    [super dealloc];
}

- (id)valueForAttribute:(NSString *)key
{
    if (_url == nil || key == nil)
    {
        return nil;
    }
    if ([key isEqualToString:NSMetadataItemURLKey])
    {
        return _url;
    }
    if ([key isEqualToString:NSMetadataItemPathKey])
    {
        return [_url path];
    }
    if ([key isEqualToString:NSMetadataItemFSNameKey] || [key isEqualToString:NSMetadataItemDisplayNameKey])
    {
        return [_url lastPathComponent];
    }
    return nil;
}

- (NSDictionary *)valuesForAttributes:(NSArray *)keys
{
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    for (NSString *key in keys)
    {
        id value = [self valueForAttribute:key];
        if (value != nil)
        {
            [values setObject:value forKey:key];
        }
    }
    return values;
}

- (NSArray *)attributes
{
    if (_url == nil)
    {
        return [NSArray array];
    }
    return [NSArray arrayWithObjects:NSMetadataItemURLKey, NSMetadataItemPathKey, NSMetadataItemFSNameKey, NSMetadataItemDisplayNameKey, nil];
}

@end

@implementation NSMetadataQueryAttributeValueTuple

- (NSString *)attribute
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (id)value
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (NSUInteger)count
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return 0;
}

@end

@implementation NSMetadataQueryResultGroup

- (NSString *)attribute
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (id)value
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (NSArray *)subgroups
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (NSUInteger)resultCount
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return 0;
}

- (id)resultAtIndex:(NSUInteger)idx
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

- (NSArray *)results
{
    NSLog(@"STUB: [%@ %@]", [self description], NSStringFromSelector(_cmd));
    return nil;
}

@end
