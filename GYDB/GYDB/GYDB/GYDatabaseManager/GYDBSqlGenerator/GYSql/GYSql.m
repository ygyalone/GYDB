//
//  GYSql.m
//  GYDB
//
//  Created by GuangYuYang on 2017/1/18.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYSql.h"
#import "GYDatabaseManager.h"

@implementation GYSql

- (instancetype)initWithSqlString:(NSString *)sqlString args:(NSArray *)args {
    if (self = [super init]) {
        _sqlString = sqlString;
        _args =args;
        DBLOG(@"%@", sqlString);
    }
    return self;
}

- (void)setSqlString:(NSString *)sqlString {
    _sqlString = sqlString;
    DBLOG(@"%@", sqlString);
}

@end
