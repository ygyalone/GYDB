//
//  NSObject+GYDB.h
//  GYDB
//
//  Created by GuangYu on 17/1/18.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYDBCondition.h"
#import "GYDBError.h"

typedef void(^GYErrorBlock)(GYDBError *error);
typedef void(^GYArrayBlock)(NSArray *  result, GYDBError *error);

@interface NSObject (GYDB)

#pragma mark - base
/**
 返回自定义对象属性的类型

 @return 字典@{自定义类型属性名:类型}
 */
+ (NSDictionary<NSString *, Class> *)gy_customClass;

/**
 返回数组中对象的类型

 @return 字典@{数组属性名:元素类型}
 */
+ (NSDictionary<NSString *, Class> *)gy_classInArray;

/**
 自定义主键值

 @return 自定义主键值
 */
- (NSString *)gy_customPrimaryKeyValue;

/**
 主键值

 @return 主键值,存入DB的对象才有值,否则为nil
 */
- (NSString *)gy_primaryKeyValue;

/**
 一对一外键值

 @return 一对一外键值,存入DB的对象才有值,否则为nil
 */
- (NSString *)gy_singleLinkID;

/**
 一对多外键值,存入DB的对象才有值,否则为nil

 @return 一对多外键值,
 */
- (NSString *)gy_multiLinkID;

#pragma mark - table
/**
 查询表类对应的数据表是否存在

 @param error   错误输出
 @return        查询结果
 */
+ (BOOL)gy_tableExistsWithError:(GYDBError **)error;
/**
 创建类对应的数据表

 @return 操作结果,nil为成功
 */
+ (GYDBError *)gy_createTable;

/**
 删除类对应的数据表

 @return 操作结果,nil为成功
 */
+ (GYDBError *)gy_dropTable;

/**
 更新类对应的数据表(只增加旧表没有的字段)

 @return 操作结果,nil为成功
 */
+ (GYDBError *)gy_updateTable;

#pragma mark - count
/**
 查询表中存储的对象数目

 @param conditon    查询条件
 @param error       错误输出
 @return            对象数目
 */
+ (NSInteger)gy_countWithCondition:(GYDBCondition *)conditon error:(GYDBError **)error;

#pragma mark - save (insert or update)
/**
 保存对象到DB,对象不在DB时insert,否则update

 @return 操作结果,nil为成功
 */
- (GYDBError *)gy_save;

/**
 gy_save异步方法

 @param completion 操作回调
 */
- (void)gy_saveWithCompletion:(GYErrorBlock)completion;


#pragma mark - insert
/**
 插入对象到DB
 注意:一次insert操作中同一个对象不会重复insert
 
 @return 操作结果,nil为成功
 */
- (GYDBError *)gy_insert;

/**
 gy_insert异步方法

 @param completion 操作回调
 */
- (void)gy_insertWithCompletion:(GYErrorBlock)completion;


#pragma mark - delete
/**
 从DB中删除对象

 @return 操作结果,nil为成功
 */
- (GYDBError *)gy_delete;

/**
 gy_delete异步方法

 @param completion 操作回调
 */
- (void)gy_deleteWithCompletion:(GYErrorBlock)completion;

/**
 删除类对应表中所有对象
 
 @return            操作结果
 */
+ (GYDBError *)gy_deleteAll;

/**
 异步gy_deleteAll方法
 
 @param completion  结果回调
 */
+ (void)gy_deleteAllWithCompletion:(GYErrorBlock)completion;


/**
 删除对应类满足条件的对象
 
 @param condition   条件对象,传nil删除全部
 @return            操作结果
 */
+ (GYDBError *)gy_deleteObjsWithCondition:(GYDBCondition *)condition;

/**
 异步gy_deleteObjsWithCondition方法
 
 @param condition   条件对象,传nil删除全部
 @param completion  结果回调
 */
+ (void)gy_deleteObjsWithCondition:(GYDBCondition * )condition completion:(GYErrorBlock)completion;



#pragma mark - query
/**
 从DB查询对象

 @param condition   查询条件,可为nil
 @param error       错误输出
 @return            查询结果
 */
+ (NSArray * )gy_queryObjsWithCondition:(GYDBCondition * )condition error:(GYDBError **)error;

/**
 异步gy_queryObjsWithCondition:error:方法

 @param condition 查询条件,可为nil
 @param completion 操作回调
 */
+ (void)gy_queryObjsWithCondition:(GYDBCondition * )condition completion:(GYArrayBlock )completion;


#pragma mark - update
/**
 更新对象到DB

 @param excludeColumns  不需要更新的属性,nil为全部更新
 @return                操作结果,nil为成功
 */
- (GYDBError *)gy_updateWithExcludeColumns:(NSArray<NSString *> * )excludeColumns;

/**
 异步gy_updateObjWithExcludeColumns:方法

 @param excludeColumns  不需要更新的属性,nil为全部更新
 @param completion      操作回调
 */
- (void)gy_updateWithExcludeColumns:(NSArray<NSString *> * )excludeColumns completion:(GYErrorBlock)completion;

@end
