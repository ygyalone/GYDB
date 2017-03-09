//
//  GYDBUtil.h
//  GYDB
//
//  Created by GuangYuYang on 2017/1/18.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "GYDBProperty.h"

#define getEncode(_encode_) [GYDBUtil getEncode:_encode_]

@interface GYDBUtil : NSObject
///uuid
+ (NSString *)uuid;
///获取所有属性
+ (NSArray<GYDBProperty *> *)propertiesWithClazz:(Class)clazz;
///绑定占位符
+ (void)bindObj:(id)obj toColumn:(unsigned int)column inStatement:(sqlite3_stmt *)stmt;
///获取类型编码
+ (const char *)getEncode:(const char*)encode;

@end
