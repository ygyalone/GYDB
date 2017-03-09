//
//  GYDBSqlGenerator.m
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYDBSqlGenerator.h"
#import "NSObject+GYDB.h"
#import "NSObject+GYExtension.h"
#import "GYDBUtil.h"
#import "GYDatabaseManager.h"

#define NotNil(_string_) (!_string_.length?@"":_string_)

@implementation GYDBSqlGenerator

#pragma mark - count
+ (GYSql *)sqlForRowCountWithClazz:(Class)clazz condition:(GYDBCondition *)condition {
    NSString *tableName = [clazz gy_className];
    NSMutableString *sqlString = [NSMutableString stringWithString:@"select count(*) from "];
    [sqlString appendString:tableName];
    if (condition.conditionString.length) {
        [sqlString appendString:condition.conditionString];
    }
    return [[GYSql alloc] initWithSqlString:sqlString args:nil];
}

#pragma mark - table
//create table
+ (void)sqlsForCreateTableWithClazz:(Class)clazz
                         sqlsArrary:(NSMutableArray *)array
                           clazzArr:(NSMutableArray *)clazzArr {
    
    if (!clazz) return;
    [clazzArr addObject:NSStringFromClass(clazz)];
    NSArray<GYDBProperty *> *props = [GYDBUtil propertiesWithClazz:clazz];
    NSMutableString *columns = [NSMutableString string];
    NSMutableArray<GYDBProperty *> *typeUnknowProps = [NSMutableArray array];
    
    //默认字段
    [columns appendFormat:@"%@ text primary key", kColumnPK];
    [columns appendFormat:@",%@ text", kColumnSingleLinkID];
    [columns appendFormat:@",%@ text", kColumnMultiLinkID];
    [columns appendFormat:@",%@ text", kColumnPropName];
    
    //基本属性字段
    [props enumerateObjectsUsingBlock:^(GYDBProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.databaseType.length) {
            [columns appendFormat:@",%@ %@", obj.databaseName, obj.databaseType];
        }else {
            [columns appendFormat:@",%@ text", obj.databaseName];
            [typeUnknowProps addObject:obj];
        }
    }];
    
    //自定义对象字段
    [typeUnknowProps enumerateObjectsUsingBlock:^(GYDBProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == GYDBPropertyTypeOBJ || obj.type == GYDBPropertyTypeOBJs) {
            Class propClass;
            if (obj.type == GYDBPropertyTypeOBJ) {
                propClass = [clazz gy_customClass][obj.propertyName];
            }else {
                propClass = [clazz gy_classInArray][obj.propertyName];
            }
            //递归
            if (![clazzArr containsObject:NSStringFromClass(propClass)]) {
                [self sqlsForCreateTableWithClazz:propClass sqlsArrary:array clazzArr:clazzArr];
            }
        }
    }];
    
    NSString *tableName = [clazz gy_className];
    NSString *sqlString = [NSMutableString stringWithFormat:@"create table if not exists %@(%@)", tableName, columns];
    [array addObject:[[GYSql alloc] initWithSqlString:sqlString args:nil]];
    return;
}

+ (NSArray<GYSql *> *)sqlsForCreateTableWithClazz:(Class)clazz {
    NSMutableArray *createSqls = [NSMutableArray array];
    NSMutableArray *clazzArr = [NSMutableArray array];
    [self sqlsForCreateTableWithClazz:clazz sqlsArrary:createSqls clazzArr:clazzArr];
    return createSqls;
}

//update table
+ (NSArray<GYSql *> *)sqlsForUpdateTableWithClazz:(Class)clazz oldColumns:(NSArray<NSString *> *)oldColumns; {
    NSArray<GYDBProperty *> *props = [GYDBUtil propertiesWithClazz:clazz];
    NSMutableArray<GYDBProperty *> *mprops = [NSMutableArray arrayWithArray:props];
    NSMutableArray *oldProps = [NSMutableArray array];
    for (GYDBProperty *prop in mprops) {
        if ([oldColumns containsObject:prop.databaseName]) {
            [oldProps addObject:prop];
        }
    }
    
    NSString *tableName = [clazz gy_className];
    [mprops removeObjectsInArray:oldProps];
    NSMutableArray *sqls = [NSMutableArray array];
    [mprops enumerateObjectsUsingBlock:^(GYDBProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableString *sqlString = nil;
        if (obj.databaseType.length) {
            sqlString = [NSMutableString stringWithFormat:@"alter table %@ add column %@ %@", tableName, obj.databaseName, obj.databaseType];
        }else {
            sqlString = [NSMutableString stringWithFormat:@"alter table %@ add column %@ TEXT", tableName, obj.databaseName];
        }
        GYSql *sql = [[GYSql alloc] initWithSqlString:sqlString args:nil];
        [sqls addObject:sql];
    }];
    return sqls;
}

#pragma mark - insert
+ (id)valueOfObj:(id)obj forProp:(GYDBProperty *)prop {
    id value = [obj valueForKey:prop.propertyName];
    if (!value) {
        value = [NSNull null];
    }
    return value;
}

+ (NSString *)sqlsForInsertObj:(id)obj
                     sqlsArray:(NSMutableArray *)sqls
                     addedObjs:(NSMutableArray *)addedObjs
                  singleLinkID:(NSString *)singleLinkID
                   multiLinkID:(NSString *)multiLinkID
                      propName:(NSString *)propName {
    
    if (!obj) return nil;
    [addedObjs addObject:obj];
    NSArray<GYDBProperty *> *props = [GYDBUtil propertiesWithClazz:[obj class]];
    NSMutableArray<GYDBProperty *> *typeUnknowProps = [NSMutableArray array];
    NSString *tableName = [[obj class] gy_className];
    NSMutableString *columns = [NSMutableString string];
    NSMutableString *placeholders = [NSMutableString string];
    NSMutableArray *args = [NSMutableArray array];
    
    //默认字段
    [columns appendString:kColumnPK];
    [columns appendFormat:@",%@",kColumnSingleLinkID];
    [columns appendFormat:@",%@",kColumnMultiLinkID];
    [columns appendFormat:@",%@",kColumnPropName];
    
    NSString *customPK = [obj gy_customPrimaryKeyValue];
    NSString *pk = [obj gy_primaryKeyValue];
    if (!pk.length) {
        pk = customPK.length?customPK:[GYDBUtil uuid];
    }
    [args addObject:pk];
    [args addObject:NotNil(singleLinkID)];
    [args addObject:NotNil(multiLinkID)];
    [args addObject:NotNil(propName)];
    [placeholders appendString:@"?,?,?,?"];
    
    //防止字符串常量或者数字常量因为主键重复导致插入失败
    if (![obj isKindOfClass:[NSString class]] &&
        ![obj isKindOfClass:[NSNumber class]]) {
        [obj setPrimaryKeyValue:pk];
        [obj setSingleLinkID:NotNil(singleLinkID)];
        [obj setMultiLinkID:NotNil(multiLinkID)];
    }
    
    //基本属性字段
    [props enumerateObjectsUsingBlock:^(GYDBProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        if (prop.type != GYDBPropertyTypeNone) {
            [columns appendFormat:@",%@", prop.databaseName];
            [placeholders appendString:@",?"];
        }
        
        if (prop.type == GYDBPropertyTypeNormal) {
            [args addObject:[self valueOfObj:obj forProp:prop]];
        }else if (prop.type == GYDBPropertyTypeOBJ) {
            [args addObject:[NSString stringWithUTF8String:prop.propertyEncode]];
        }else if (prop.type == GYDBPropertyTypeOBJs) {
            [args addObject:NotNil(NSStringFromClass([[obj class] gy_classInArray][prop.propertyName]))];
        }
        
        if (!prop.databaseType.length)  [typeUnknowProps addObject:prop];
    }];
    NSMutableString *insertSql = [NSMutableString stringWithFormat:@"insert into %@ (%@) values(%@)", tableName, columns, placeholders];
    [sqls addObject:[[GYSql alloc] initWithSqlString:insertSql args:args]];
    
    [typeUnknowProps enumerateObjectsUsingBlock:^(GYDBProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        //递归
        if (prop.type == GYDBPropertyTypeOBJ) {
            id customObj = [obj valueForKey:prop.propertyName];
            if (customObj && ![addedObjs containsObject:customObj]) {
                [self sqlsForInsertObj:customObj sqlsArray:sqls addedObjs:addedObjs singleLinkID:pk multiLinkID:nil propName:prop.propertyName];
            }
        }else if (prop.type == GYDBPropertyTypeOBJs) {
            NSArray *customObjs = [obj valueForKey:prop.propertyName];
            if (![customObjs conformsToProtocol:@protocol(NSFastEnumeration)]) return;
            [customObjs enumerateObjectsUsingBlock:^(id  _Nonnull customObj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![addedObjs containsObject:customObj]) {
                    [self sqlsForInsertObj:customObj sqlsArray:sqls addedObjs:addedObjs singleLinkID:nil multiLinkID:pk propName:prop.propertyName];
                }
            }];
        }
    }];
    return tableName;
}

+ (NSArray<GYSql *> *)sqlsForInsertObj:(id)obj {
    NSMutableArray *insertSqls = [NSMutableArray array];
    NSMutableArray *addedObjs = [NSMutableArray array];
    [self sqlsForInsertObj:obj sqlsArray:insertSqls addedObjs:addedObjs singleLinkID:nil multiLinkID:nil propName:nil];
    return insertSqls;
}

#pragma mark - delete
+ (void)sqlsForDeleteObj:(id)obj
                      sqlsArray:(NSMutableArray *)array
                    deletedObjs:(NSMutableArray *)deletedObjs
                      condition:(GYDBCondition *)condition{
    
    if (![obj gy_primaryKeyValue] || [deletedObjs containsObject:obj]) {
        return;
    }
    [deletedObjs addObject:obj];
    
    GYSql *sql = [[GYSql alloc] init];
    NSString *tableName = [[obj class] gy_className];
    sql.sqlString = [NSString stringWithFormat:@"delete from %@%@", tableName, condition.conditionString];
    
    NSArray<GYDBProperty *> *props = [GYDBUtil propertiesWithClazz:[obj class]];
    [props enumerateObjectsUsingBlock:^(GYDBProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        if (prop.type == GYDBPropertyTypeOBJ) {
            //递归
            id customObj = [obj valueForKey:prop.propertyName];
            GYDBCondition * c = [GYDBCondition condition].Where(kColumnSingleLinkID).Eq([obj gy_primaryKeyValue]);
            [self sqlsForDeleteObj:customObj sqlsArray:array deletedObjs:deletedObjs condition:c];
            
        }else if (prop.type == GYDBPropertyTypeOBJs) {
            NSArray *customObjs = [obj valueForKey:prop.propertyName];
            [customObjs enumerateObjectsUsingBlock:^(id  _Nonnull customObj, NSUInteger idx, BOOL * _Nonnull stop) {
                //递归
                GYDBCondition * c = [GYDBCondition condition].Where(kColumnMultiLinkID).Eq([obj gy_primaryKeyValue]);
                [self sqlsForDeleteObj:customObj sqlsArray:array deletedObjs:deletedObjs condition:c];
            }];
        }
    }];
    
    [array addObject:sql];
}

+ (NSArray<GYSql *> *)sqlsForDeleteObj:(id)obj {
    NSMutableArray *deleteSqls = [NSMutableArray array];
    NSMutableArray *deletedObjs = [NSMutableArray array];
    GYDBCondition *condition = [GYDBCondition condition].Where(kColumnPK).Eq([obj gy_primaryKeyValue]);
    [self sqlsForDeleteObj:obj sqlsArray:deleteSqls deletedObjs:deletedObjs condition:condition];
    return deleteSqls;
}

#pragma mark -query
+ (GYSql *)sqlForQueryObjWithClazz:(Class)clazz condition:(GYDBCondition *)condition {
    NSString *tableName = [clazz gy_className];
    NSString *conditionString = @"";
    if (condition.conditionString.length) {
        conditionString = condition.conditionString;
    }
    NSString *sqlString = [NSString stringWithFormat:@"select * from %@%@", tableName, conditionString];
    GYSql *sql = [[GYSql alloc] initWithSqlString:sqlString args:nil];
    return sql;
}

+ (GYSql *)sqlForQueryObjWithClazz:(Class)clazz primaryKey:(NSString *)pk {
    NSString *tableName = [clazz gy_className];
    return [self sqlForQueryObjWithTableName:tableName primaryKey:pk];
}

+ (GYSql *)sqlForQueryObjWithTableName:(NSString *)tableName primaryKey:(NSString *)pk {
    NSString *conditionString = @"";
    if (pk.length) {
        conditionString = [GYDBCondition condition].Where(kColumnPK).Eq(pk).conditionString;
    }
    NSString *sqlString = [NSString stringWithFormat:@"select * from %@%@", tableName, NotNil(conditionString)];
    GYSql *sql = [[GYSql alloc] initWithSqlString:sqlString args:nil];
    return sql;
}

+ (GYSql *)sqlForQueryObjWithClazz:(Class)clazz propName:(NSString *)propName singleLinkID:(NSString *)singleLinkID {
    NSString *tableName = [clazz gy_className];
    return [self sqlForQueryObjWithTableName:tableName propName:propName singleLinkID:singleLinkID];
}

+ (GYSql *)sqlForQueryObjWithTableName:(NSString *)tableName propName:(NSString *)propName singleLinkID:(NSString *)singleLinkID {
    NSString *conditionString = [GYDBCondition condition].Where(kColumnSingleLinkID).Eq(singleLinkID).And(kColumnPropName).Eq(propName).conditionString;
    NSString *sqlString = [NSString stringWithFormat:@"select * from %@%@", tableName, NotNil(conditionString)];
    GYSql *sql = [[GYSql alloc] initWithSqlString:sqlString args:nil];
    return sql;
}

+ (GYSql *)sqlForQueryObjWithClazz:(Class)clazz propName:(NSString *)propName multiLinkID:(NSString *)multiLinkID {
    NSString *tableName = [clazz gy_className];
    return [self sqlForQueryObjWithTableName:tableName propName:propName multiLinkID:multiLinkID];
}

+ (GYSql *)sqlForQueryObjWithTableName:(NSString *)tableName propName:(NSString *)propName multiLinkID:(NSString *)multiLinkID {
    NSString *conditionString = [GYDBCondition condition].Where(kColumnMultiLinkID).Eq(multiLinkID).And(kColumnPropName).Eq(propName).conditionString;
    NSString *sqlString = [NSString stringWithFormat:@"select * from %@%@", tableName, NotNil(conditionString)];
    GYSql *sql = [[GYSql alloc] initWithSqlString:sqlString args:nil];
    return sql;
}

#pragma mark - update
+ (NSArray<GYDBProperty *> *)enabledPropsForObj:(id)obj columns:(NSArray<NSString *> *)columns {
    NSArray<GYDBProperty *> *props = [GYDBUtil propertiesWithClazz:[obj class]];
    NSMutableArray<GYDBProperty *> *enabledProps = [NSMutableArray array];
    [props enumerateObjectsUsingBlock:^(GYDBProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!columns.count || [columns containsObject:prop.propertyName]) {
            [enabledProps addObject:prop];
        }
    }];
    return enabledProps;
}

+ (void)sqlsForUpdateObj:(id)obj
             withColumns:(NSArray<NSString *> *)columns
               sqlsArray:(NSMutableArray *)array
             updatedObjs:(NSMutableArray *)updatedObjs {
    
    if (!obj || [updatedObjs containsObject:obj]) {
        return;
    }
    [updatedObjs addObject:obj];
    
    NSString *tableName = [[obj class] gy_className];
    NSString *pk = [obj gy_primaryKeyValue];
    NSString *condition = [GYDBCondition condition].Where(kColumnPK).Eq(pk).conditionString;
    
    NSMutableArray *args = [NSMutableArray array];
    NSArray<GYDBProperty *> *enabledProps = [self enabledPropsForObj:obj columns:columns];
    NSMutableString *keyValuesString = [NSMutableString string];
    
    [enabledProps enumerateObjectsUsingBlock:^(GYDBProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        if (prop.type == GYDBPropertyTypeNormal) {
            [keyValuesString appendFormat:@" %@ = ?,", prop.propertyName];
            id value = [obj valueForKey:prop.propertyName];
            if (!value) {
                value = [NSNull null];
            }
            [args addObject:value];
        }else if (prop.type == GYDBPropertyTypeOBJ) {
            //递归
            id customObj = [obj valueForKey:prop.propertyName];
            [self sqlsForUpdateObj:customObj withColumns:nil sqlsArray:array updatedObjs:updatedObjs];
        }else if (prop.type == GYDBPropertyTypeOBJs) {
            //递归
            id customObjs = [obj valueForKey:prop.propertyName];
            [customObjs enumerateObjectsUsingBlock:^(id  _Nonnull customObj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self sqlsForUpdateObj:customObj withColumns:nil sqlsArray:array updatedObjs:updatedObjs];
            }];
        }
    }];
    
    if (keyValuesString.length) {
        if ([keyValuesString hasSuffix:@","]) {
            keyValuesString = [NSMutableString stringWithString:[keyValuesString substringToIndex:keyValuesString.length-1]];
        }
        NSString *sqlString = [NSString stringWithFormat:@"update %@ set%@%@", tableName, keyValuesString, condition];
        GYSql *sql = [[GYSql alloc] initWithSqlString:sqlString args:args];
        [array addObject:sql];
    }
}

+ (NSArray<GYSql *> *)sqlsForUpdateObj:(id)obj withColumns:(NSArray<NSString *> *)columns {
    NSMutableArray *updateSqls = [NSMutableArray array];
    NSMutableArray *updatedObjs = [NSMutableArray array];
    [self sqlsForUpdateObj:obj withColumns:columns sqlsArray:updateSqls updatedObjs:updatedObjs];
    return updateSqls;
}

#pragma mark - other
+ (GYSql *)sqlForTableColumnsWithClazz:(Class)clazz {
    NSString *tableName = [clazz gy_className];
    NSString *sqlString = [NSString stringWithFormat:@"pragma table_info(%@)",tableName];
    return [[GYSql alloc] initWithSqlString:sqlString args:nil];
}

@end
