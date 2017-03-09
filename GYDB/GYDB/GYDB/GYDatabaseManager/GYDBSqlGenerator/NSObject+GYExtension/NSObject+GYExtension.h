//
//  NSObject+GYExtension.h
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSObject (GYExtension)
+ (NSString *)gy_className;
- (NSString *)gy_className;
+ (objc_property_t *)gy_propertiesCount:(unsigned int *)outCount;
@end
