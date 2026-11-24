#import <Foundation/Foundation.h>
#import <Foundation/NSByteCountFormatter.h>
#import <Foundation/NSZone.h>
#import <objc/runtime.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

void *NSAllocateCollectable(NSUInteger size, NSUInteger options)
{
	(void)options;
	return calloc(1, size ? size : 1);
}

BOOL NSBOOLFromString(NSString *string)
{
	return [string boolValue];
}

int NSExtensionMain(int argc, const char *argv[])
{
	(void)argc;
	(void)argv;
	return 0;
}

NSUInteger NSHashCString(const char *string)
{
	if (!string) return 0;
	NSUInteger hash = (NSUInteger)5381;
	for (const unsigned char *p = (const unsigned char *)string; *p; ++p)
		hash = ((hash << 5) + hash) ^ *p;
	return hash;
}

NSString *NSLocalizedFileSizeDescription(unsigned long long byteCount)
{
	return [NSByteCountFormatter stringFromByteCount:(long long)byteCount
										  countStyle:NSByteCountFormatterCountStyleFile];
}

NSZone *NSMallocZone(void)
{
	return NSDefaultMallocZone();
}

void NSRequestConcreteImplementation(Class cls, SEL selector)
{
	const char *className = cls ? class_getName(cls) : "<unknown class>";
	const char *selectorName = selector ? sel_getName(selector) : "<unknown selector>";
	[NSException raise:NSInvalidArgumentException
			format:@"%s %s requires a subclass implementation", className, selectorName];
}

NSString *NSStringFromBOOL(BOOL value)
{
	return value ? @"YES" : @"NO";
}

NSStringEncoding _NSDefaultFileSystemEncoding(void)
{
	return NSUTF8StringEncoding;
}

NSDictionary *_NSDictionaryOfVariableBindings(NSString *keyNames, id firstValue, ...)
{
	NSMutableDictionary *bindings = [[NSMutableDictionary alloc] init];
	if (!keyNames || ![keyNames length] || !firstValue) return [bindings autorelease];

	NSArray *keys = [keyNames componentsSeparatedByString:@","];
	va_list args;
	va_start(args, firstValue);
	id value = firstValue;
	for (NSString *rawKey in keys) {
		if (!value) break;
		NSString *key = [rawKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		if ([key length]) [bindings setObject:value forKey:key];
		value = va_arg(args, id);
	}
	va_end(args);
	return [bindings autorelease];
}

NSError *_NSErrorWithFilePathAndErrno(id path, int errorNumber)
{
	NSString *pathKey = [path isKindOfClass:[NSURL class]] ? NSURLErrorKey : NSFilePathErrorKey;
	NSString *reason = [NSString stringWithFormat:@"%s", strerror(errorNumber)];
	NSError *underlying = [NSError errorWithDomain:NSPOSIXErrorDomain
											   code:errorNumber
											 userInfo:@{NSLocalizedDescriptionKey: reason}];
	NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObject:underlying
													 forKey:NSUnderlyingErrorKey];
	if (path) [info setObject:path forKey:pathKey];
	return [NSError errorWithDomain:NSPOSIXErrorDomain code:errorNumber userInfo:info];
}

id _NSConvertToASCIIorUnicode2(void)
{
	return nil;
}
