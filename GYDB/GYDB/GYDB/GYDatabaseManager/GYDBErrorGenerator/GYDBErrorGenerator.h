//
//  GYDBSqlExecuter.h
//  GYDB
//
//  Created by GuangYu on 17/3/1.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "GYDBError.h"

#define DBCurrentError  [GYDBErrorGenerator sharedInstance].currentError
#define DBUpdateError(_database_, _result_, _expectResult_) [[GYDBErrorGenerator sharedInstance] updateErrorWithDatabase:_database_ result:_result_ expectResult:_expectResult_]

@interface GYDBErrorGenerator : NSObject
+ (instancetype)sharedInstance;
- (BOOL)updateErrorWithDatabase:(sqlite3 *)database
                         result:(int)result
                   expectResult:(int)expectResult;
@property (nonatomic, readonly) GYDBError *currentError;
@end
