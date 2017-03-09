//
//  GYDBQueryHandler.h
//  GYDB
//
//  Created by GuangYuYang on 2017/1/19.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class GYDBCondition;

NS_ASSUME_NONNULL_BEGIN
@interface GYDBQueryHandler : NSObject

/**
 查询对象
 
 @param clazz       类
 @param condition   查询条件
 @param database    数据库
 @return            返回对象或者对象数组，没有结果或者操作失败时返回nil
 */
+ (NSArray * __nullable)queryObjsWithClazz:(Class)clazz condition:(GYDBCondition * __nullable)condition database:(sqlite3 *)database;

@end
NS_ASSUME_NONNULL_END
