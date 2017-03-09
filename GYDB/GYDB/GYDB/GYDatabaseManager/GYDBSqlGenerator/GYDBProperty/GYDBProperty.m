//
//  GYDBProperty.m
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYDBProperty.h"
#import "GYDBUtil.h"

@implementation GYDBProperty

- (instancetype)initWithPropertyEncode:(const char *)propertyEncode {
    if (self = [super init]) {
        _propertyEncode = propertyEncode;
    }
    return self;
}

- (instancetype)initWithObjcProp:(objc_property_t)prop {
    if (self = [super init]) {
        _type = GYDBPropertyTypeNone;
        [self setObjcProp:prop];
    }
    return self;
}

+ (instancetype)stringProp {
    GYDBProperty *prop = [[self alloc] initWithPropertyEncode:getEncode(@encode(NSString))];
    [prop setValue:@"self" forKey:@"propertyName"];
    [prop setValue:@"NSString" forKey:@"databaseName"];
    [prop setValue:@"TEXT" forKey:@"databaseType"];
    [prop setValue:@(GYDBPropertyTypeNormal) forKey:@"type"];
    return prop;
}

+ (instancetype)numberProp {
    GYDBProperty *prop = [[self alloc] initWithPropertyEncode:getEncode(@encode(NSNumber))];
    [prop setValue:@"self" forKey:@"propertyName"];
    [prop setValue:@"NSNumber" forKey:@"databaseName"];
    [prop setValue:@"REAL" forKey:@"databaseType"];
    [prop setValue:@(GYDBPropertyTypeNormal) forKey:@"type"];
    return prop;
}

+ (instancetype)dateProp {
    GYDBProperty *prop = [[self alloc] initWithPropertyEncode:getEncode(@encode(NSDate))];
    [prop setValue:@"self" forKey:@"propertyName"];
    [prop setValue:@"NSDate" forKey:@"databaseName"];
    [prop setValue:@"TIMESTAMP" forKey:@"databaseType"];
    [prop setValue:@(GYDBPropertyTypeNormal) forKey:@"type"];
    return prop;
}

+ (instancetype)dataProp {
    GYDBProperty *prop = [[self alloc] initWithPropertyEncode:getEncode(@encode(NSData))];
    [prop setValue:@"self" forKey:@"propertyName"];
    [prop setValue:@"NSData" forKey:@"databaseName"];
    [prop setValue:@"BLOB" forKey:@"databaseType"];
    [prop setValue:@(GYDBPropertyTypeNormal) forKey:@"type"];
    return prop;
}

+ (instancetype)propertyWithObjcProp:(objc_property_t)prop {
    return [[self alloc] initWithObjcProp:prop];
}

- (void)setObjcProp:(objc_property_t)prop {
    _propertyName = [NSString stringWithUTF8String:property_getName(prop)];
    _databaseName = [NSString stringWithUTF8String:property_getName(prop)];
    [self setTypeWithProp:prop];
}

- (void)setTypeWithProp:(objc_property_t)prop{
    unsigned int outCount;
    objc_property_attribute_t *attrs = property_copyAttributeList(prop, &outCount);
    for (int i = 0; i < outCount; i++) {
        objc_property_attribute_t attr = attrs[i];
        if (strcmp(attr.name, "T") == 0) {
            _databaseType = [self databaseTypeWithAttr:attr];
            if (_databaseType.length) {
                _type = GYDBPropertyTypeNormal;
            }
            break;
        }
    }
    free(attrs);
}

- (NSString *)databaseTypeWithAttr:(objc_property_attribute_t)attr {
    const char *type = getEncode(attr.value);
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
