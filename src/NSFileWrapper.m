/* Copyright (c) 2007 Dirk Theisen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// 01/08/2007 original - Dirk Theisen

#import <Foundation/NSFileWrapper.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSKeyedUnarchiver.h>

enum {
	NSFileWrapperKindRegularFile = 0,
	NSFileWrapperKindDirectory = 1,
	NSFileWrapperKindSymbolicLink = 2
};

@interface NSFileWrapperFile : NSFileWrapper {
	NSData* contentData;
}

@end

@interface NSFileWrapperDirectory : NSFileWrapper {
	NSMutableDictionary* contentDictionary;
}

@end

@interface NSFileWrapperLink : NSFileWrapper {	
	NSString* linkDestination;
}

@end

@implementation NSFileWrapper

+ (id) alloc
{
	static NSFileWrapper* sharedInstance = nil;
	if (!sharedInstance) sharedInstance = [super alloc];
	return sharedInstance;
}

- (BOOL) updateFromPath: (NSString*) path attributes: (NSDictionary*) attrs
{
    [_path release];
    _path = [path copy];
    _fileAttributes = [[attrs mutableCopy] retain];
    return attrs != nil;
}

- (BOOL) updateFromPath: (NSString*) path
{
	if ([self needsToBeUpdatedFromPath: path]) {
		[_fileAttributes release];
		_fileAttributes = nil;
		NSDictionary* attrs = [[NSFileManager defaultManager] fileAttributesAtPath: path traverseLink: NO];
		return [self updateFromPath: path attributes: attrs];
	}
	return NO;
}

/**
 * Init an instance from the file, directory, or symbolic link at the given absolute path.<br /> 
 */
- (id) initWithPath: (NSString*)path
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSFileManager* fm = [NSFileManager defaultManager];
	
	if (NSDebugEnabled) NSLog(@"NSFileWrapper", @"initWithPath: %@", path);
	NSDictionary* attrs = [[fm fileAttributesAtPath: path traverseLink: NO] retain];
	
	NSString* fileType = [attrs fileType];
	if ([fileType isEqualToString: NSFileTypeDirectory]) {
		self = [self initDirectoryWithFileWrappers: nil];
    } else if ([fileType isEqualToString: NSFileTypeRegular]) {
		self = [self initRegularFileWithContents: nil];
    } else if ([fileType isEqualToString: NSFileTypeSymbolicLink]) {
		self = [self initSymbolicLinkWithDestination: 
			nil];
    } else {
		self = nil; // should never happen
	}
	[self updateFromPath: path attributes: attrs];

	// Store the full path in filename, the specification is unclear in this point
	[self setFilename: [path lastPathComponent]];
	[self setPreferredFilename: [self filename]];
	
	[pool release];
	return self;
}

- (NSData*) regularFileContents
{
	[NSException raise: NSInternalInconsistencyException format: @"Try to access regular file content of something not regular file."];
	return nil;
}

- (NSString*) symbolicLinkDestination
{
	[NSException raise: NSInternalInconsistencyException format: @"Try to access symbolic link destination of something not a link wrapper."];
	return nil;
}


// Init and return an instance for a regular file type
- (id) initRegularFileWithContents: (NSData*) data
{
	return [[NSFileWrapperFile alloc] initRegularFileWithContents: data];
}

// Init and return an instance for a directory type
- (id) initDirectoryWithFileWrappers: (NSDictionary*) docs;
{	
	return [[NSFileWrapperDirectory alloc] initDirectoryWithFileWrappers: docs];
}

// Init and return an instance for a symbolic link type
- (id) initSymbolicLinkWithDestination: (NSString*) path
{
	return [[NSFileWrapperLink alloc] initSymbolicLinkWithDestination: path];
}

- (id) initSymbolicLinkWithDestinationURL: (NSURL*) url
{
	return [self initSymbolicLinkWithDestination: [url path]];
}

- (NSURL*) symbolicLinkDestinationURL
{
	NSString* destination = [self symbolicLinkDestination];
	return destination ? [NSURL fileURLWithPath: destination] : nil;
}

- (NSString*) addRegularFileWithContents: (NSData*) data preferredFilename: (NSString*) fileName
{
	NSFileWrapper* child = [[[NSFileWrapper class] alloc] initRegularFileWithContents: data];
	[child setPreferredFilename: fileName];
	NSString* key = [self addFileWrapper: child];
	[child release];
	return key;
}

- (id) icon
{
	return _icon;
}

- (void) setIcon: (id) icon
{
	if (icon != _icon) {
		[_icon autorelease];
		_icon = [icon retain];
	}
}

- (void) encodeWithCoder: (NSCoder*) coder
{
	NSInteger kind;
	if ([self isDirectory]) {
		kind = NSFileWrapperKindDirectory;
		[coder encodeObject: [self fileWrappers] forKey: @"NSFileWrapperChildren"];
	} else if ([self isSymbolicLink]) {
		kind = NSFileWrapperKindSymbolicLink;
		[coder encodeObject: [self symbolicLinkDestination] forKey: @"NSFileWrapperLinkDestination"];
	} else {
		kind = NSFileWrapperKindRegularFile;
		[coder encodeObject: [self regularFileContents] forKey: @"NSFileWrapperContents"];
	}
	[coder encodeInteger: kind forKey: @"NSFileWrapperKind"];
	[coder encodeObject: _preferredFilename forKey: @"NSFileWrapperPreferredFilename"];
	[coder encodeObject: _filename forKey: @"NSFileWrapperFilename"];
	[coder encodeObject: _fileAttributes forKey: @"NSFileWrapperAttributes"];
}

- (id) initWithCoder: (NSCoder*) coder
{
	if (![coder allowsKeyedCoding]) {
		[NSException raise: NSInvalidArgumentException format: @"NSFileWrapper can only be decoded by keyed coders"];
		return nil;
	}

	NSInteger kind = [coder decodeIntegerForKey: @"NSFileWrapperKind"];
	NSFileWrapper* wrapper = nil;
	switch (kind) {
		case NSFileWrapperKindDirectory: {
			NSSet* classes = [NSSet setWithObjects: [NSDictionary class], [NSString class], [NSFileWrapper class], nil];
			NSDictionary* children = [coder decodeObjectOfClasses: classes forKey: @"NSFileWrapperChildren"];
			wrapper = [[[NSFileWrapper class] alloc] initDirectoryWithFileWrappers: children];
			break;
		}
		case NSFileWrapperKindSymbolicLink: {
			NSString* destination = [coder decodeObjectOfClass: [NSString class] forKey: @"NSFileWrapperLinkDestination"];
			wrapper = [[[NSFileWrapper class] alloc] initSymbolicLinkWithDestination: destination];
			break;
		}
		case NSFileWrapperKindRegularFile: {
			NSData* contents = [coder decodeObjectOfClass: [NSData class] forKey: @"NSFileWrapperContents"];
			wrapper = [[[NSFileWrapper class] alloc] initRegularFileWithContents: contents];
			break;
		}
		default:
			break;
	}

	// The base class instance is a shared placeholder that must not be released.
	if ([self class] != [NSFileWrapper class]) {
		[self release];
	}
	if (wrapper == nil) {
		return nil;
	}

	NSString* preferred = [coder decodeObjectOfClass: [NSString class] forKey: @"NSFileWrapperPreferredFilename"];
	if ([preferred length]) {
		[wrapper setPreferredFilename: preferred];
	}
	NSString* filename = [coder decodeObjectOfClass: [NSString class] forKey: @"NSFileWrapperFilename"];
	if ([filename length]) {
		[wrapper setFilename: filename];
	}
	NSSet* attrClasses = [NSSet setWithObjects: [NSDictionary class], [NSString class], [NSNumber class], [NSDate class], nil];
	NSDictionary* attributes = [coder decodeObjectOfClasses: attrClasses forKey: @"NSFileWrapperAttributes"];
	if (attributes) {
		[wrapper setFileAttributes: attributes];
	}
	return wrapper;
}

- (NSData*) serializedRepresentation
{
	return [NSKeyedArchiver archivedDataWithRootObject: self];
}

- (id) initWithSerializedRepresentation: (NSData*) data
{
	if ([data length] == 0) {
		return nil;
	}
	id wrapper = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	if (![wrapper isKindOfClass: [NSFileWrapper class]]) {
		return nil;
	}
	return [wrapper retain];
}

- (NSString *)filename
{
	return _filename;
}

- (void) setFilename: (NSString*) filename 
{
	if ([filename length]) {
		if (filename != _filename) {
			[_filename autorelease];
			_filename = [filename retain];
		}
		return;
	}	
	[NSException raise: NSInternalInconsistencyException format: @"-[NSFileWrapper setFilename:] filename may not be nil or empty."];
}

- (NSString*) preferredFilename
{
	return _preferredFilename;
}


- (void) setPreferredFilename: (NSString*) preferredFilename 
{
	if ([preferredFilename length]) {
		if (preferredFilename != _preferredFilename) {
			[_preferredFilename autorelease];
			_preferredFilename = [preferredFilename retain];
		}
		return;
	}
	[NSException raise: NSInternalInconsistencyException format: @"-[NSFileWrapper setPreferredFilename:] preferredFilename may not be nil or empty."];
}

- (void) setFileAttributes: (NSDictionary*) attributes
{
	if (! _fileAttributes) {
		_fileAttributes = [[NSMutableDictionary alloc] init];
    }
	
	[_fileAttributes addEntriesFromDictionary: attributes];
}

- (NSDictionary*) fileAttributes
{
	return _fileAttributes;
}

- (BOOL) isRegularFile
{
	return NO;
}

- (BOOL) isDirectory
{
	return NO;
}

- (BOOL) isSymbolicLink
{
	return NO;
}

- (void)removeFileWrapper: (NSFileWrapper *)wrapper
{
	[NSException raise: NSInternalInconsistencyException format: @"-[NSFileWrapper %@] sent to a non directory file wrapper.", NSStringFromSelector(_cmd)];
}


- (NSString*) addFileWrapper: (NSFileWrapper*) wrapper
{
	[NSException raise: NSInternalInconsistencyException format: @"-[NSFileWrapper %@] sent to a non directory file wrapper.", NSStringFromSelector(_cmd)];
	return nil;
}

- (NSDictionary*) fileWrappers
{
	[NSException raise: NSInternalInconsistencyException format: @"-[NSFileWrapper %@] sent to a non directory file wrapper.", NSStringFromSelector(_cmd)];
	return nil;
}

- (BOOL) writeToFile: (NSString*) path
         atomically: (BOOL) atomicFlag
    updateFilenames: (BOOL) updateFilenamesFlag
{
	NSAssert(NO, @"Implemented in concrete subclasses.");
	return NO;
}


- (BOOL) needsToBeUpdatedFromPath: (NSString*) path
{
	NSDate* changeDateSelf = [[self fileAttributes] fileModificationDate];
	NSDate* changeDatePath = [[[NSFileManager defaultManager] fileAttributesAtPath: path 
																	  traverseLink: NO] fileModificationDate];
	return [changeDatePath compare: changeDateSelf] > 0;
}


- (void) dealloc
{
    [_path release];
	[_fileAttributes release];
	[_preferredFilename release];
	[_filename release];
	[super dealloc];
}


@end

@implementation NSFileWrapperFile

+ (id) alloc
{
	return NSAllocateObject(self, 0, NULL);
}

// Init instance of regular file type
- (id) initRegularFileWithContents: (NSData*) data
{	
	if ((self = [self init])!=nil) {
		contentData = [data copy];
	} 
	return self;
}


- (BOOL) updateFromPath: (NSString*) path attributes: (NSDictionary*) attrs
{
	if ([super updateFromPath: path attributes: attrs]) {
		[contentData release];
        contentData = nil;
		
		return YES;
	}
	return NO;
}

- (BOOL) isRegularFile
{
	return YES;
}

- (NSData*) regularFileContents
{
    if (contentData == nil) {
        unsigned long long length = [[self fileAttributes] fileSize];
        contentData = length < 8192*160 ? [[NSData alloc] initWithContentsOfFile: _path] : [[NSData alloc] initWithContentsOfMappedFile: _path]; // use some treshhold to not thrash for big files - can we run out of file handles here?
    }
	return contentData;
}

- (BOOL) writeToFile: (NSString*) path
		  atomically: (BOOL) atomicFlag
	 updateFilenames: (BOOL) updateFilenamesFlag
{
	BOOL result = [[self regularFileContents] writeToFile: path 
											   atomically: atomicFlag];
	if ([self fileAttributes]) {
		[[NSFileManager defaultManager] changeFileAttributes: [self fileAttributes]
													  atPath: path];
	}
	if (updateFilenamesFlag) {
		[self setFilename: [path lastPathComponent]];
	}
	return result;
}

- (BOOL)   writeToURL: (NSURL *) url
              options: (NSFileWrapperWritingOptions) options
  originalContentsURL: (NSURL *) originalContentsURL
                error: (NSError **)error
{
	BOOL result = [[self regularFileContents] writeToURL: url
	                                             options: (options & NSFileWrapperWritingAtomic) != 0 ? NSDataWritingAtomic : 0
	                                               error: error];
	if (result && (options & NSFileWrapperWritingWithNameUpdating) != 0) {
		[NSException raise: NSInvalidArgumentException format: @"TODO: NSFileWrapperWritingWithNameUpdating"];
	}
	return result;
}

- (void) dealloc
{
	[contentData release];
	[super dealloc];
}

@end

@implementation NSFileWrapperDirectory

- (id) initDirectoryWithFileWrappers: (NSDictionary*) docs;
{
	if ((self = [self init])!=nil) {
		contentDictionary = [docs mutableCopy];
		
		NSEnumerator* ke = [contentDictionary keyEnumerator];
		NSString* name;
		while ((name = [ke nextObject])!=nil) {
			NSFileWrapper* wrapper = [contentDictionary objectForKey: name];
			if ([[wrapper preferredFilename] length] == 0) {
				[wrapper setPreferredFilename: name];
			}
		}
	}	
	return self;
}

- (BOOL) isDirectory
{
	return YES;
}

- (NSDictionary*) fileWrappers
{
		return contentDictionary;
}

- (NSString*) addFileWrapper: (NSFileWrapper*) wrapper
{
	if (!contentDictionary) {
		contentDictionary = [[NSMutableDictionary alloc] init]; 
	}
	NSParameterAssert([[wrapper preferredFilename] length]>0);
	NSString* name = [wrapper preferredFilename];
	while ([contentDictionary objectForKey: name]) {
		// append random number to prefered name:
		name = [NSString stringWithFormat: @"%@-%x", [wrapper preferredFilename], rand()];
	}
	[contentDictionary setObject: wrapper forKey: name];
	return name;
}


- (BOOL) writeToFile: (NSString*) path
		  atomically: (BOOL) atomicFlag
	 updateFilenames: (BOOL) updateFilenamesFlag
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSDictionary* wrappers = [self fileWrappers];
	NSEnumerator* enumerator = [wrappers keyEnumerator];
	NSString* key;
	BOOL result = YES;
	
	[fm createDirectoryAtPath: path attributes: [self fileAttributes]];
	if ([self fileAttributes]) {
		[[NSFileManager defaultManager] changeFileAttributes: [self fileAttributes]
													  atPath: path];
	}
	while ((key = [enumerator nextObject])) {
		NSString* newPath = [path stringByAppendingPathComponent: key];
		result &= [[wrappers objectForKey: key] writeToFile: newPath
												 atomically: atomicFlag
											updateFilenames: updateFilenamesFlag];
	}
	
	if (updateFilenamesFlag) {
		[self setFilename: [path lastPathComponent]];
	}
	return result;
}


- (void) removeFileWrapper: (NSFileWrapper*) wrapper
{
	NSArray* keys = [contentDictionary allKeysForObject: wrapper];
	if ([keys count]) {
		[contentDictionary removeObjectsForKeys: keys];
	}
}

- (BOOL) updateFromPath: (NSString*) path attributes: (NSDictionary*) attrs
{	
	if ([super updateFromPath: path attributes: attrs]) {
		
		NSMutableDictionary* newContentDictionary = [[NSMutableDictionary alloc] init];
		NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath: path];
		NSString* filename;
		
		while ((filename = [enumerator nextObject]) != nil) {
			[enumerator skipDescendents];
			NSString* absolutePath = [path stringByAppendingPathComponent: filename];
			// Try to recycle an old wrapper (and data!)
			NSFileWrapper* wrapper = [contentDictionary objectForKey: filename];
			if (wrapper) {
				// Update recycled wrapper:
				[wrapper updateFromPath: absolutePath];
			} else {
				// Create new one:
				wrapper = [[[NSFileWrapper class] alloc] initWithPath: absolutePath];
			}
			[newContentDictionary setObject: wrapper forKey: filename]; 
			[wrapper release];
		}	
		
		[contentDictionary release];
		contentDictionary = newContentDictionary;
		return YES;
	}
	return NO;
}

+ (id) alloc
{
	return NSAllocateObject(self, 0, NULL);
}

- (void) dealloc
{
	[contentDictionary release];
	[super dealloc];
}


@end

@implementation NSFileWrapperLink

- (id) initSymbolicLinkWithDestination: (NSString*) path
{	
	if ((self = [self init])!=nil) {
		linkDestination = [path copy];
	}	
	return self;
}

- (BOOL) isSymbolicLink
{
	return YES;
}

- (NSString*) symbolicLinkDestination
{
	return linkDestination;
}

- (BOOL) writeToFile: (NSString*) path
		  atomically: (BOOL) atomicFlag
	 updateFilenames: (BOOL) updateFilenamesFlag
{
	BOOL result = [[NSFileManager defaultManager] createSymbolicLinkAtPath: path 
															   pathContent: [self symbolicLinkDestination]];
	if ([self fileAttributes]) {
		[[NSFileManager defaultManager] changeFileAttributes: [self fileAttributes]
													  atPath: path];
	}
	if (updateFilenamesFlag) {
		[self setFilename: [path lastPathComponent]];
	}
	return result;
}

- (BOOL) updateFromPath: (NSString*) path attributes: (NSDictionary*) attrs
{	
	if ([super updateFromPath: path attributes: attrs]) {
		[linkDestination release];
		linkDestination = [[[NSFileManager defaultManager] pathContentOfSymbolicLinkAtPath: path] copy];
		return YES;
	}
	return NO;
}

+ (id) alloc
{
	return NSAllocateObject(self, 0, NULL);
}

- (void) dealloc
{
	[linkDestination release];
	[super dealloc];
}


@end
