//
//  GYDBIvar.h
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

typedef enum GYDBIvarType {
    GYDBIvarTypeNone,   ///<未知属性
    GYDBIvarTypeNormal, ///<普通属性
    GYDBIvarTypeOBJ,    ///<关联属性
    GYDBIvarTypeOBJs    ///<数组关联属性
}GYDBIvarType;

//obj每一个成员变量对应一个GYDBIvar
@interface GYDBIvar : NSObject

@property (nonatomic, readonly) NSString *propertyName;     ///<obj中属性名
@property (nonatomic, readonly) const char *propertyEncode; ///<编码类型
@property (nonatomic, readonly) NSString *fieldName;        ///<字段名
@property (nonatomic, readonly) NSString *databaseType;     ///<字段类型
@property (nonatomic, assign) GYDBIvarType type;        ///<属性类型

//基本类的prop对象,分别对应:NSString,NSMutableString,NSNumber,NSDate,NSData
+ (instancetype)stringProp;
+ (instancetype)numberProp;
+ (instancetype)dateProp;
+ (instancetype)dataProp;

//+ (instancetype)propertyWithObjcProp:(objc_property_t)prop;
+ (instancetype)propertyWithObjcIvar:(Ivar)ivar;

@end
