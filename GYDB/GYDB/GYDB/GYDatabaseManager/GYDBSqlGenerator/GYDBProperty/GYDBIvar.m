//
//  GYDBIvar.m
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYDBIvar.h"
#import "GYDBUtil.h"

@implementation GYDBIvar

- (instancetype)initWithPropertyEncode:(const char *)propertyEncode {
    if (self = [super init]) {
        _propertyEncode = propertyEncode;
    }
    return self;
}

- (instancetype)initWithObjcIvar:(Ivar)ivar {
    if (self = [super init]) {
        _type = GYDBIvarTypeNone;
        [self setObjcIvar:ivar];
    }
    return self;
}

+ (instancetype)stringProp {
    GYDBIvar *prop = [[self alloc] initWithPropertyEncode:getEncode(@encode(NSString))];
    [prop setValue:@"self" forKey:@"propertyName"];
    [prop setValue:@"NSString" forKey:@"fieldName"];
    [prop setValue:@"TEXT" forKey:@"databaseType"];
    [prop setValue:@(GYDBIvarTypeNormal) forKey:@"type"];
    return prop;
}

+ (instancetype)numberProp {
    GYDBIvar *prop = [[self alloc] initWithPropertyEncode:getEncode(@encode(NSNumber))];
    [prop setValue:@"self" forKey:@"propertyName"];
    [prop setValue:@"NSNumber" forKey:@"fieldName"];
    [prop setValue:@"REAL" forKey:@"databaseType"];
    [prop setValue:@(GYDBIvarTypeNormal) forKey:@"type"];
    return prop;
}

+ (instancetype)dateProp {
    GYDBIvar *prop = [[self alloc] initWithPropertyEncode:getEncode(@encode(NSDate))];
    [prop setValue:@"self" forKey:@"propertyName"];
    [prop setValue:@"NSDate" forKey:@"fieldName"];
    [prop setValue:@"TIMESTAMP" forKey:@"databaseType"];
    [prop setValue:@(GYDBIvarTypeNormal) forKey:@"type"];
    return prop;
}

+ (instancetype)dataProp {
    GYDBIvar *prop = [[self alloc] initWithPropertyEncode:getEncode(@encode(NSData))];
    [prop setValue:@"self" forKey:@"propertyName"];
    [prop setValue:@"NSData" forKey:@"fieldName"];
    [prop setValue:@"BLOB" forKey:@"databaseType"];
    [prop setValue:@(GYDBIvarTypeNormal) forKey:@"type"];
    return prop;
}

+ (instancetype)propertyWithObjcIvar:(Ivar)ivar {
    return [[self alloc] initWithObjcIvar:ivar];
}

- (void)setObjcIvar:(Ivar)ivar {
    NSString *name = [NSString stringWithUTF8String:ivar_getName(ivar)];
    if ([name hasPrefix:@"_"]) {
        name = [name substringFromIndex:1];
    }
    _propertyName = name;
    _fieldName = name;
    [self setTypeWithIvar:ivar];
}

- (void)setTypeWithIvar:(Ivar)ivar{
    const char *type = ivar_getTypeEncoding(ivar);
    _databaseType = [self databaseTypeWithIvarType:type];
    if (_databaseType.length) {
        _type = GYDBIvarTypeNormal;
    }
}

- (NSString *)databaseTypeWithIvarType:(const char *)type {
    type = getEncode(type);
    if (!strcmp(type, getEncode(@encode(char))) ||
        !strcmp(type, getEncode(@encode(short))) ||
        !strcmp(type, getEncode(@encode(int))) ||
        !strcmp(type, getEncode(@encode(long))) ||
        !strcmp(type, getEncode(@encode(long long))) ||
        !strcmp(type, getEncode(@encode(unsigned char))) ||
        !strcmp(type, getEncode(@encode(unsigned short))) ||
        !strcmp(type, getEncode(@encode(unsigned int))) ||
        !strcmp(type, getEncode(@encode(unsigned long))) ||
        !strcmp(type, getEncode(@encode(unsigned long long)))) {
        _propertyEncode = getEncode(@encode(int));
        return @"INTEGER";
    }else if (!strcmp(type, getEncode(@encode(float))) ||
              !strcmp(type, getEncode(@encode(double)))) {
        _propertyEncode = getEncode(@encode(double));
        return @"REAL";
    }else if (!strcmp(type, getEncode(@encode(NSString)))) {
        _propertyEncode = getEncode(@encode(NSString));
        return @"TEXT";
    }else if (!strcmp(type, getEncode(@encode(NSMutableString)))) {
        _propertyEncode = getEncode(@encode(NSMutableString));
        return @"TEXT";
    }else if (!strcmp(type, getEncode(@encode(NSNumber)))) {
        _propertyEncode = getEncode(@encode(NSNumber));
        return @"REAL";
    }else if (!strcmp(type, getEncode(@encode(NSDate)))) {
        _propertyEncode = getEncode(@encode(NSDate));
        return @"TIMESTAMP";
    }else if (!strcmp(type, getEncode(@encode(NSData)))) {
        _propertyEncode = getEncode(@encode(NSData));
        return @"BLOB";
    }else {
        _propertyEncode = type;
        return nil;
    }
}

@end
