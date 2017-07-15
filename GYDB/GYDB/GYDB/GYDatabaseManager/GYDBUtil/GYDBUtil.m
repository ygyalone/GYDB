//
//  GYDBUtil.m
//  GYDB
//
//  Created by GuangYuYang on 2017/1/18.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYDBUtil.h"
#import "NSObject+GYExtension.h"
#import "NSObject+GYDB.h"

@implementation GYDBUtil

+ (NSString *)uuid{
    //如果对象没有返回主键值,则每次生成不同的唯一标识作为主键值
    return [[NSUUID UUID] UUIDString];
}

//获取所有属性
+ (NSArray<GYDBProperty *> *)propertiesWithClazz:(Class)clazz {
    if ([clazz isSubclassOfClass:[NSString class]]) {
        return @[[GYDBProperty stringProp]];
    }else if ([clazz isSubclassOfClass:[NSNumber class]]) {
        return @[[GYDBProperty numberProp]];
    }else if ([clazz isSubclassOfClass:[NSDate class]]) {
        return @[[GYDBProperty dateProp]];
    }else if ([clazz isSubclassOfClass:[NSData class]]) {
        return @[[GYDBProperty dataProp]];
    }
    
    NSMutableArray<GYDBProperty *> *databaseProperties = [NSMutableArray array];
    unsigned int count = 0;
    objc_property_t *properties = [clazz gy_propertiesCount:&count];
    for (int i = 0; i < count; i++) {
        GYDBProperty *prop = [GYDBProperty propertyWithObjcProp:properties[i]];
        if ([[clazz gy_customClass].allKeys containsObject:prop.propertyName]) {
            prop.type = GYDBPropertyTypeOBJ;
        }else if ([[clazz gy_classInArray].allKeys containsObject:prop.propertyName]) {
            prop.type = GYDBPropertyTypeOBJs;
        }
        [databaseProperties addObject:prop];
    }
    free(properties);
    return databaseProperties;
}

+ (void)bindObj:(id)obj toColumn:(unsigned int)column inStatement:(sqlite3_stmt *)stmt {
    if (!obj || [obj isKindOfClass:[NSNull class]]) {
        sqlite3_bind_null(stmt, column);
    }else if ([obj isKindOfClass:[NSNumber class]]) {
        if (strcmp([obj objCType], @encode(char)) == 0 ||
            strcmp([obj objCType], @encode(unsigned char)) == 0 ||
            strcmp([obj objCType], @encode(short)) == 0 ||
            strcmp([obj objCType], @encode(unsigned short)) == 0 ||
            strcmp([obj objCType], @encode(int)) == 0 ||
            strcmp([obj objCType], @encode(unsigned int)) == 0 ||
            strcmp([obj objCType], @encode(long)) == 0 ||
            strcmp([obj objCType], @encode(unsigned long)) == 0 ||
            strcmp([obj objCType], @encode(long long)) == 0 ||
            strcmp([obj objCType], @encode(unsigned long long)) == 0) {
            sqlite3_bind_int(stmt, column, [obj intValue]);
        }else if (strcmp([obj objCType], @encode(float)) == 0 ||
                  strcmp([obj objCType], @encode(double)) == 0) {
            sqlite3_bind_double(stmt, column, [obj doubleValue]);
        }else if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            sqlite3_bind_int(stmt, column, [obj boolValue] ? 1 : 0);
        }else {
            sqlite3_bind_double(stmt, column, [obj doubleValue]);
        }
    }else if ([obj isKindOfClass:[NSDate class]]) {
        sqlite3_bind_double(stmt, column, [obj timeIntervalSince1970]);
    }else if ([obj isKindOfClass:[NSData class]]) {
        const void *bytes = [obj bytes];
        sqlite3_bind_blob(stmt, column, bytes, (int)[obj length], NULL);
    }else {
        sqlite3_bind_text(stmt, column, [obj description].UTF8String, -1, NULL);
    }
}

+ (const char *)getEncode:(const char*)encode {
    NSString *encodeString = [NSString stringWithUTF8String:encode];
    NSRange range = [encodeString rangeOfString:@"\\b\\w+\\b" options:NSRegularExpressionSearch];
    if (range.location == NSNotFound) {
        return "";
    }
    return [encodeString substringWithRange:range].UTF8String;
}

@end
