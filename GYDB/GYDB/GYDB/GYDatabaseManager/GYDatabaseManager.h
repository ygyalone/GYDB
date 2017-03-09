//
//  GYDatabaseManager.h
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYDBError.h"
#import "GYDBCondition.h"

#define DBManager [GYDatabaseManager sharedManager]

#ifdef DEBUG
#define DBLOG(...) if ([GYDatabaseManager sharedManager].openLog) {\
                        NSLog(__VA_ARGS__);\
                    }
#else
#define DBLOG(...)
#endif

typedef void(^GYErrorBlock)(GYDBError *error);
typedef void(^GYArrayBlock)(NSArray *  result, GYDBError *error);

@interface GYDatabaseManager : NSObject
+ (instancetype)sharedManager;

///是否开启日志
@property (nonatomic, assign) BOOL openLog;
///default:SandBox/Document/gydb/gydb.sqlite
@property (readonly) NSString *databasePath;
///异步回调block时的队列,默认为manager的异步队列
@property (nonatomic, strong) dispatch_queue_t completionQueue;

#pragma mark - database

/**
 打开(创建)数据库

 @param dbPath  数据库路径
 @return        操作结果
 */
- (GYDBError *)openDatabase:(NSString *)dbPath;

/**
 关闭数据库

 @param dbPath  数据库路径
 @return        操作结果
 */
- (GYDBError *)closeDatabase:(NSString *)dbPath;

#pragma mark - count
/**
 查询表中数据行数

 @param clazz       需要查询的类
 @param conditon    查询条件,无条件传nil
 @param error       错误输出
 @return            行数
 */
- (NSInteger)rowCountForClazz:(Class)clazz
                    condition:(GYDBCondition *)conditon
                        error:(GYDBError **)error;

#pragma mark - table
///<检查该类对应的数据表是否存在
- (BOOL)tableExistsForClazz:(Class)clazz error:(GYDBError **)error;
- (GYDBError *)createTableForClazz:(Class)clazz;   ///<创建该类对应的数据表
- (GYDBError *)dropTableForClazz:(Class)clazz;     ///<删除该类对应的数据表
- (GYDBError *)updateTableForClazz:(Class)clazz;   ///<更新该类对应的数据表(只增加旧表没有的字段)

#pragma mark - save
/**
 对象不存在时insert,否则update

 @param obj 需要保存的对象
 @return    操作结果
 */
- (GYDBError *)saveObj:(id)obj;

/**
 异步save

 @param obj         需要保存的对象
 @param completion  结果回调
 */
- (void)saveObj:(id)obj completion:(GYErrorBlock )completion;

#pragma mark - insert
/**
 注意:一次insert操作中同一个对象不会重复insert
 比如属性A和属性B包含了同一个对象，那么只会insert属性A中的对象

 @param obj 需要插入的对象
 @return    操作结果
 */
- (GYDBError *)insertObj:(id)obj;

/**
 异步insert

 @param obj         需要插入的对象
 @param completion  结果回调
 */
- (void)insertObj:(id)obj completion:(GYErrorBlock)completion;


/**
 插入数组中的对象

 @param objs    对象数组
 @return        操作结果
 */
- (GYDBError *)insertObjs:(NSArray *)objs;

/**
 异步insert

 @param objs        对象数组
 @param completion  结果回调
 */
- (void)insertObjs:(NSArray *)objs completion:(GYErrorBlock)completion;

#pragma mark - delete
/**
 删除对象

 @param obj 需要删除的对象
 @return    操作结果
 */
- (GYDBError *)deleteObj:(id)obj;

/**
 异步delete

 @param obj         需要删除的对象
 @param completion  结果回调
 */
- (void)deleteObj:(id)obj completion:(GYErrorBlock)completion;

/**
 删除对应类满足条件的对象
 
 @param clazz       类
 @param condition   条件对象,传nil删除所有
 @return            操作结果
 */
- (GYDBError *)deleteObjsWithClazz:(Class)clazz condition:(GYDBCondition *)condition;

/**
 异步deleteAll
 
 @param clazz       类
 @param condition   条件对象
 @param completion  结果回调
 */
- (void)deleteObjsWithClazz:(Class)clazz
                  condition:(GYDBCondition * )condition
                 completion:(GYErrorBlock)completion;

#pragma mark - query
/**
 查询该类满足条件的对象
 
 @param clazz       类
 @param condition   条件对象,传nil查询所有
 @return            对象数组
 */
- (NSArray * )queryObjsForClazz:(Class)clazz
                      condition:(GYDBCondition * )condition
                          error:(GYDBError **)error;

/**
 异步query
 
 @param clazz       类
 @param condition   条件对象,传nil查询所有
 @param completion  结果回调
 */
- (void)queryObjsForClazz:(Class)clazz
                condition:(GYDBCondition * )condition
               completion:(GYArrayBlock )completion;

#pragma mark - update
/**
 更新对象

 @param obj             需要更新的对象
 @param excludeColumns  不需要更新的字段，传nil更新全部字段
 @return                操作结果
 */
- (GYDBError *)updateObj:(id)obj excludeColumns:(NSArray<NSString *> * )excludeColumns;

/**
 异步update

 @param obj             需要更新的对象
 @param excludeColumns  不需要更新的字段，传nil更新全部字段
 @param completion      结果回调
 */
- (void)updateObj:(id)obj
   excludeColumns:(NSArray<NSString *> * )excludeColumns
       completion:(GYErrorBlock)completion;

/**
 更新数组中的对象

 @param objs            需要更新的对象数组
 @param excludeColumns  不需要更新的字段，传nil更新全部字段
 @return                操作结果
 */
- (GYDBError *)updateObjs:(NSArray *)objs excludeColumns:(NSArray<NSString *> * )excludeColumns;

/**
 异步update

 @param objs            需要更新的对象数组
 @param excludeColumns  不需要更新的字段，传nil更新全部字段
 @param completion      操作结果
 */
- (void)updateObjs:(NSArray *)objs
    excludeColumns:(NSArray<NSString *> * )excludeColumns
        completion:(GYErrorBlock)completion;

@end

