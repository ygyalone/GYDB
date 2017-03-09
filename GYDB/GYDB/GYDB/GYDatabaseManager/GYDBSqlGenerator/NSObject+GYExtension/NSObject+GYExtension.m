//
//  NSObject+GYExtension.m
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "NSObject+GYExtension.h"

@implementation NSObject (GYExtension)
+ (NSString *)gy_className {
    if ([self isSubclassOfClass:[NSString class]]) {
        return NSStringFromClass([NSString class]);
    }else if ([self isSubclassOfClass:[NSNumber class]]) {
        return NSStringFromClass([NSNumber class]);
    }else if ([self isSubclassOfClass:[NSDate class]]) {
        return NSStringFromClass([NSDate class]);
    }else if ([self isSubclassOfClass:[NSData class]]) {
        return NSStringFromClass([NSData class]);
    }
    
    return NSStringFromClass(self);
}

- (NSString *)gy_className {
    return NSStringFromClass([self class]);
}

+ (objc_property_t *)gy_propertiesCount:(unsigned int *)outCount {
    return class_copyPropertyList([self class], outCount);
}

@end
