//
//  GYDBSqlGenerator.h
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYSql.h"
#import "GYDBCondition.h"

#define kColumnSingleLinkID     @"_single_link_id"  //一对一外键
#define kColumnMultiLinkID      @"_multi_link_id"   //一对多外键
#define kColumnPropName         @"_prop_name"       //属性名字段(区分作为属性的嵌套对象)

//固定字段索引
#define kIndexPK                0   ///<主键
#define kIndexSingleLinkID      1   ///<一对一外键
#define kIndexMultiLinkID       2   ///<一对多外键
#define kIndexPropName          3   ///<该条数据对应的属性名

//字段索引偏移,每张表前面会有固定4个字段
#define kColumnIndexOffset      4

@protocol GYDBStorageProtocol <NSObject>

- (void)setPrimaryKeyValue:(NSString *)primaryKeyValue;
- (void)setSingleLinkID:(NSString *)singleLinkID;
- (void)setMultiLinkID:(NSString *)multiLinkID;

@end

@interface GYDBSqlGenerator : NSObject

#pragma mark - count
+ (GYSql *)sqlForRowCountWithClazz:(Class)clazz condition:(GYDBCondition *)condition;

#pragma mark - table
+ (NSArray<GYSql *> *)sqlsForCreateTableWithClazz:(Class)clazz;
+ (NSArray<GYSql *> *)sqlsForUpdateTableWithClazz:(Class)clazz oldColumns:(NSArray<NSString *> *)oldColumns;

#pragma mark - insert
+ (NSArray<GYSql *> *)sqlsForInsertObj:(id)obj;

#pragma mark - delete
+ (NSArray<GYSql *> *)sqlsForDeleteObj:(id)obj;

#pragma mark -query
+ (GYSql *)sqlForQueryObjWithClazz:(Class)clazz condition:(GYDBCondition *)condition;
+ (GYSql *)sqlForQueryObjWithClazz:(Class)clazz primaryKey:(NSString *)pk;
+ (GYSql *)sqlForQueryObjWithTableName:(NSString *)tableName primaryKey:(NSString *)pk;
+ (GYSql *)sqlForQueryObjWithTableName:(NSString *)tableName propName:(NSString *)propName singleLinkID:(NSString *)singleLinkID;
+ (GYSql *)sqlForQueryObjWithTableName:(NSString *)tableName propName:(NSString *)propName multiLinkID:(NSString *)multiLinkID;

#pragma mark - update
+ (NSArray<GYSql *> *)sqlsForUpdateObj:(id)obj withColumns:(NSArray<NSString *> *)columns;

#pragma mark - other
+ (GYSql *)sqlForTableColumnsWithClazz:(Class)clazz;

@end
