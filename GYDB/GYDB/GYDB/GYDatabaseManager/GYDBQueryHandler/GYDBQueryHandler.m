//
//  GYDBQueryHandler.m
//  GYDB
//
//  Created by GuangYuYang on 2017/1/19.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYDBQueryHandler.h"
#import "GYDBSqlGenerator.h"
#import "GYDBErrorGenerator.h"
#import "GYDBUtil.h"
#import "NSObject+GYDB.h"
#import <objc/runtime.h>

#define NotNull(_cstring_) (_cstring_?_cstring_:"")

@implementation GYDBQueryHandler
+ (NSArray * __nullable)queryObjsWithClazz:(Class)clazz condition:(GYDBCondition * __nullable)condition database:(sqlite3 *)database {
    NSMutableArray *objs = [NSMutableArray array];
    GYSql *sql = [GYDBSqlGenerator sqlForQueryObjWithClazz:clazz condition:condition];
    sqlite3_stmt *stmt;
    if (DBUpdateError(database, sqlite3_prepare_v2(database, sql.sqlString.UTF8String, -1, &stmt, NULL), SQLITE_OK)) {
        while (DBUpdateError(database, sqlite3_step(stmt), SQLITE_ROW)) {
            id obj = [[clazz alloc] init];
            [self setValueToObj:obj withDatabase:database sqliteStmt:stmt];
            id value = objc_getAssociatedObject(obj, @selector(setValue:forKey:toObj:));
            if (value) {
                [value setPrimaryKeyValue:[obj gy_primaryKeyValue]];
                [value setSingleLinkID:[obj gy_singleLinkID]];
                [value setMultiLinkID:[obj gy_multiLinkID]];
                obj = value;
                objc_setAssociatedObject(obj, @selector(setValue:forKey:toObj:), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            [objs addObject:obj];
        }
        sqlite3_finalize(stmt);
        return objs;
    }
    sqlite3_finalize(stmt);
    return nil;
}

+ (id __nullable)queryObjWithClazz:(Class)clazz
                         tableName:(NSString *)tableName
                          database:(sqlite3 *)database
                          propName:(NSString *)propName
                      singleLinkID:(NSString *)singleLinkID {
    GYSql *sql = [GYDBSqlGenerator sqlForQueryObjWithTableName:tableName propName:propName singleLinkID:singleLinkID];
    sqlite3_stmt *stmt;
    if (DBUpdateError(database, sqlite3_prepare_v2(database, sql.sqlString.UTF8String, -1, &stmt, NULL), SQLITE_OK)) {
        if(DBUpdateError(database, sqlite3_step(stmt), SQLITE_ROW)) {
            NSString *pk = [NSString stringWithUTF8String:NotNull((const char *)sqlite3_column_text(stmt, 0))];
            if ([pk isEqualToString:singleLinkID]) {
                //防止同类型嵌套导致无限递归
                sqlite3_finalize(stmt);
                return nil;
            }
            id obj = [[clazz alloc] init];
            [self setValueToObj:obj withDatabase:database sqliteStmt:stmt];
            id value = objc_getAssociatedObject(obj, @selector(setValue:forKey:toObj:));
            if (value) {
                [value setPrimaryKeyValue:[obj gy_primaryKeyValue]];
                [value setSingleLinkID:[obj gy_singleLinkID]];
                [value setMultiLinkID:[obj gy_multiLinkID]];
                obj = value;
                objc_setAssociatedObject(obj, @selector(setValue:forKey:toObj:), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            sqlite3_finalize(stmt);
            return obj;
        }
    }
    sqlite3_finalize(stmt);
    return nil;
}

+ (void)queryObjWithClazz:(Class)clazz
                tableName:(NSString *)tableName
                 database:(sqlite3 *)database
                 propName:(NSString *)propName
                   multiLinkID:(NSString *)multiLinkID
             containerArr:(NSMutableArray *)container {
    
    GYSql *sql = [GYDBSqlGenerator sqlForQueryObjWithTableName:tableName propName:propName multiLinkID:multiLinkID];
    sqlite3_stmt *stmt;
    if (DBUpdateError(database, sqlite3_prepare_v2(database, sql.sqlString.UTF8String, -1, &stmt, NULL), SQLITE_OK)) {
        while (DBUpdateError(database, sqlite3_step(stmt), SQLITE_ROW)) {
            //NSNumber的init方法会返回nil...
            id obj = nil;
            if ([clazz isSubclassOfClass:[NSNumber class]])
                obj = [[NSNumber alloc] initWithDouble:0];
            else
                obj = [[clazz alloc] init];
            
            [self setValueToObj:obj withDatabase:database sqliteStmt:stmt];
            id value = objc_getAssociatedObject(obj, @selector(setValue:forKey:toObj:));
            if (value) {
                [value setPrimaryKeyValue:[obj gy_primaryKeyValue]];
                [value setSingleLinkID:[obj gy_singleLinkID]];
                [value setMultiLinkID:[obj gy_multiLinkID]];
                obj = value;
                objc_setAssociatedObject(obj, @selector(setValue:forKey:toObj:), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            [container addObject:obj];
        }
    }
    sqlite3_finalize(stmt);
}

+ (GYDBProperty *)propInProps:(NSArray<GYDBProperty *> *)props byColumnName:(const char*)columnName {
    NSString *cName = [NSString stringWithUTF8String:columnName];
    __block GYDBProperty *prop;
    [props enumerateObjectsUsingBlock:^(GYDBProperty * _Nonnull p, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([p.databaseName isEqualToString:cName]) {
            prop = p;
            *stop = YES;
        }
    }];
    return prop;
}

+ (void)setValueToObj:(id)obj
             withDatabase:(sqlite3 *)database
           sqliteStmt:(sqlite3_stmt *)stmt {
    
    int columnCount = sqlite3_column_count(stmt);
    //获取主键和外键
    for (int i = 0; i < columnCount; i++) {
        NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(stmt, i)];
        if ([columnName isEqualToString:kColumnPK]) {
            NSString *primaryKey = [NSString stringWithUTF8String:NotNull((const char *)sqlite3_column_text(stmt, i))];
            [obj setPrimaryKeyValue:primaryKey];
        }else if ([columnName isEqualToString:kColumnSingleLinkID]) {
            NSString *singleLinkID = [NSString stringWithUTF8String:NotNull((const char *)sqlite3_column_text(stmt, i))];
            [obj setSingleLinkID:singleLinkID];
        }else if ([columnName isEqualToString:kColumnMultiLinkID]) {
            NSString *multiLinkID = [NSString stringWithUTF8String:NotNull((const char *)sqlite3_column_text(stmt, i))];
            [obj setMultiLinkID:multiLinkID];
        }
        if ([obj gy_primaryKeyValue].length &&
            [obj gy_singleLinkID].length &&
            [obj gy_multiLinkID].length) {
            break;
        }
    }
    
    //设值
    Class clazz = [obj class];
    NSString *pk = [obj gy_primaryKeyValue];
    NSArray<GYDBProperty *> *props = [GYDBUtil propertiesWithClazz:clazz];
    for (int i = 0; i < columnCount; i++) {
        GYDBProperty *prop = [self propInProps:props byColumnName:sqlite3_column_name(stmt, i)];
        if (!props) {
            continue;
        }
        
        if (prop.type == GYDBPropertyTypeNormal) {
            if (strcmp(prop.propertyEncode, getEncode(@encode(int))) == 0) {
                int value = sqlite3_column_int(stmt, i);
                [obj setValue:@(value) forKey:prop.propertyName];
            }else if (strcmp(prop.propertyEncode, getEncode(@encode(double))) == 0) {
                double value = sqlite3_column_double(stmt, i);
                [obj setValue:@(value) forKey:prop.propertyName];
            }else if (strcmp(prop.propertyEncode, getEncode(@encode(NSString))) == 0) {
                NSString *value = [NSString stringWithUTF8String:NotNull((const char *)sqlite3_column_text(stmt, i))];
                [self setValue:value forKey:prop.propertyName toObj:obj];
            }else if (strcmp(prop.propertyEncode, getEncode(@encode(NSMutableString))) == 0) {
                NSMutableString *value = [NSMutableString stringWithUTF8String:NotNull((const char *)sqlite3_column_text(stmt, i))];
                [self setValue:value forKey:prop.propertyName toObj:obj];
            }else if (strcmp(prop.propertyEncode, getEncode(@encode(NSNumber))) == 0) {
                NSNumber *value = @(sqlite3_column_double(stmt, i));
                [self setValue:value forKey:prop.propertyName toObj:obj];
            }else if (strcmp(prop.propertyEncode, getEncode(@encode(NSDate))) == 0) {
                double value = sqlite3_column_double(stmt, i);
                if (value) {
                    [self setValue:[NSDate dateWithTimeIntervalSince1970:value] forKey:prop.propertyName toObj:obj];
                }
            }else if (strcmp(prop.propertyEncode, getEncode(@encode(NSData))) == 0) {
                const void *bytes = sqlite3_column_blob(stmt, i);
                unsigned int length = sqlite3_column_bytes(stmt, i);
                [self setValue:[NSData dataWithBytes:bytes length:length] forKey:prop.propertyName toObj:obj];
            }
        }else if (prop.type == GYDBPropertyTypeOBJ) {
            NSString *tableName = [NSString stringWithUTF8String:NotNull((const char *)sqlite3_column_text(stmt, i))];
            id value = [self queryObjWithClazz:NSClassFromString([NSString stringWithUTF8String:prop.propertyEncode])
                                     tableName:tableName
                                      database:database
                                      propName:prop.propertyName
                                  singleLinkID:pk];
            [self setValue:value forKey:prop.propertyName toObj:obj];
            
        }else if (prop.type == GYDBPropertyTypeOBJs) {
            NSMutableArray *value = [NSMutableArray array];
            NSString *tableName = [NSString stringWithUTF8String:NotNull((const char *)sqlite3_column_text(stmt, i))];
            [self queryObjWithClazz:[clazz gy_classInArray][prop.propertyName]
                          tableName:tableName
                           database:database
                           propName:prop.propertyName
                        multiLinkID:pk
                       containerArr:value];
            if (strcmp(prop.propertyEncode, getEncode(@encode(NSArray))) == 0) {
                value = [value copy];
            }
            [self setValue:value forKey:prop.propertyName toObj:obj];
        }
    }
}

+ (void)setValue:(id)value forKey:(NSString *)key toObj:(id)obj{
    if ([[obj class] isSubclassOfClass:[NSString class]] ||
        [[obj class] isSubclassOfClass:[NSNumber class]] ||
        [[obj class] isSubclassOfClass:[NSDate class]] ||
        [[obj class] isSubclassOfClass:[NSData class]]) {
        objc_setAssociatedObject(obj, @selector(setValue:forKey:toObj:), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }else {
        [obj setValue:value forKey:key];
    }
}

@end
