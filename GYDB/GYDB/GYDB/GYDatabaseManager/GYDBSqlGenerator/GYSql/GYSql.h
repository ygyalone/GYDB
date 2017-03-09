//
//  GYSql.h
//  GYDB
//
//  Created by GuangYuYang on 2017/1/18.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GYSql : NSObject

@property (nonatomic, copy) NSString *sqlString;
@property (nonatomic, copy) NSArray *args;

- (instancetype)initWithSqlString:(NSString *)sqlString args:(NSArray *)args;

@end
