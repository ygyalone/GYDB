//
//  GYDBError.m
//  GYDB
//
//  Created by GuangYu on 17/2/26.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYDBError.h"

@implementation GYDBError

+ (instancetype)errorWithCode:(GYDBErrorCode)code message:(NSString *)message {
    GYDBError *error = [[GYDBError alloc] init];
    [error setValue:@(code) forKey:@"code"];
    [error setValue:message forKey:@"message"];
    return error;
}

@end
