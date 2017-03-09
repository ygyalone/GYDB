//
//  GYDBSqlExecuter.m
//  GYDB
//
//  Created by GuangYu on 17/3/1.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYDBErrorGenerator.h"

@implementation GYDBErrorGenerator
@synthesize currentError = _currentError;

+ (instancetype)sharedInstance {
    static GYDBErrorGenerator *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }
    });
    return sharedInstance;
}

- (BOOL)updateErrorWithDatabase:(sqlite3 *)database
                         result:(int)result
                   expectResult:(int)expectResult {
    if (!database) {
        _currentError = [GYDBError errorWithCode:GYDBErrorCode_SQLITE_CANTOPEN message:@"Unable to open the database file"];
    }
    if (result != expectResult) {
        int errCode = sqlite3_errcode(database);
        if (errCode == SQLITE_DONE) {
            _currentError = nil;
        }else {
            const char* errMsg = sqlite3_errmsg(database);
            _currentError = [GYDBError errorWithCode:errCode message:[NSString stringWithUTF8String:errMsg]];
        }
    }else {
        _currentError = nil;
    }
    return result == expectResult;
}

- (GYDBError *)currentError {
    //每次读取后清空错误
    GYDBError *currentError = _currentError;
    _currentError = nil;
    return currentError;
}

@end
