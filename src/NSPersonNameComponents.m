#import <Foundation/NSPersonNameComponents.h>
#import <Foundation/NSCoder.h>

@implementation NSPersonNameComponents

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (NSString *)namePrefix { return _namePrefix; }
- (NSString *)givenName { return _givenName; }
- (NSString *)middleName { return _middleName; }
- (NSString *)familyName { return _familyName; }
- (NSString *)nameSuffix { return _nameSuffix; }
- (NSString *)nickname { return _nickname; }
- (NSPersonNameComponents *)phoneticRepresentation { return _phoneticRepresentation; }

- (void)setNamePrefix:(NSString *)value
{
    if (_namePrefix != value) {
        [_namePrefix release];
        _namePrefix = [value copy];
    }
}

- (void)setGivenName:(NSString *)value
{
    if (_givenName != value) {
        [_givenName release];
        _givenName = [value copy];
    }
}

- (void)setMiddleName:(NSString *)value
{
    if (_middleName != value) {
        [_middleName release];
        _middleName = [value copy];
    }
}

- (void)setFamilyName:(NSString *)value
{
    if (_familyName != value) {
        [_familyName release];
        _familyName = [value copy];
    }
}

- (void)setNameSuffix:(NSString *)value
{
    if (_nameSuffix != value) {
        [_nameSuffix release];
        _nameSuffix = [value copy];
    }
}

- (void)setNickname:(NSString *)value
{
    if (_nickname != value) {
        [_nickname release];
        _nickname = [value copy];
    }
}

- (void)setPhoneticRepresentation:(NSPersonNameComponents *)value
{
    if (_phoneticRepresentation != value) {
        [_phoneticRepresentation release];
        _phoneticRepresentation = [value copy];
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    NSPersonNameComponents *copy = [[[self class] allocWithZone:zone] init];
    copy->_namePrefix = [_namePrefix copy];
    copy->_givenName = [_givenName copy];
    copy->_middleName = [_middleName copy];
    copy->_familyName = [_familyName copy];
    copy->_nameSuffix = [_nameSuffix copy];
    copy->_nickname = [_nickname copy];
    copy->_phoneticRepresentation = [_phoneticRepresentation copy];
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_namePrefix forKey:@"NS.namePrefix"];
    [coder encodeObject:_givenName forKey:@"NS.givenName"];
    [coder encodeObject:_middleName forKey:@"NS.middleName"];
    [coder encodeObject:_familyName forKey:@"NS.familyName"];
    [coder encodeObject:_nameSuffix forKey:@"NS.nameSuffix"];
    [coder encodeObject:_nickname forKey:@"NS.nickname"];
    [coder encodeObject:_phoneticRepresentation forKey:@"NS.phoneticRepresentation"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _namePrefix = [[coder decodeObjectOfClass:[NSString class] forKey:@"NS.namePrefix"] copy];
        _givenName = [[coder decodeObjectOfClass:[NSString class] forKey:@"NS.givenName"] copy];
        _middleName = [[coder decodeObjectOfClass:[NSString class] forKey:@"NS.middleName"] copy];
        _familyName = [[coder decodeObjectOfClass:[NSString class] forKey:@"NS.familyName"] copy];
        _nameSuffix = [[coder decodeObjectOfClass:[NSString class] forKey:@"NS.nameSuffix"] copy];
        _nickname = [[coder decodeObjectOfClass:[NSString class] forKey:@"NS.nickname"] copy];
        _phoneticRepresentation = [[coder decodeObjectOfClass:[NSPersonNameComponents class] forKey:@"NS.phoneticRepresentation"] copy];
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (![other isKindOfClass:[NSPersonNameComponents class]])
        return NO;
    NSPersonNameComponents *o = other;
#define SAME(a, b) ((a) == (b) || [(a) isEqual:(b)])
    return SAME(_namePrefix, o->_namePrefix) && SAME(_givenName, o->_givenName) &&
           SAME(_middleName, o->_middleName) && SAME(_familyName, o->_familyName) &&
           SAME(_nameSuffix, o->_nameSuffix) && SAME(_nickname, o->_nickname) &&
           SAME(_phoneticRepresentation, o->_phoneticRepresentation);
#undef SAME
}

- (NSUInteger)hash
{
    return [_givenName hash] ^ ([_familyName hash] << 1) ^ ([_middleName hash] << 2);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> {prefix=%@ given=%@ middle=%@ family=%@ suffix=%@ nickname=%@}",
            [self class], self, _namePrefix, _givenName, _middleName, _familyName, _nameSuffix, _nickname];
}

- (void)dealloc
{
    [_namePrefix release];
    [_givenName release];
    [_middleName release];
    [_familyName release];
    [_nameSuffix release];
    [_nickname release];
    [_phoneticRepresentation release];
    [super dealloc];
}

@end
