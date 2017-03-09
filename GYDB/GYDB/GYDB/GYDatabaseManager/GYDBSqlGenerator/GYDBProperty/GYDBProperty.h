//
//  GYDBProperty.h
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

typedef enum GYDBPropertyType {
    GYDBPropertyTypeNone,   ///<未知属性
    GYDBPropertyTypeNormal, ///<普通属性
    GYDBPropertyTypeOBJ,    ///<关联属性
    GYDBPropertyTypeOBJs    ///<数组关联属性
}GYDBPropertyType;

//obj每一个property对应一个GYDBProperty
@interface GYDBProperty : NSObject

@property (nonatomic, readonly) NSString *propertyName;     ///<obj中属性名
@property (nonatomic, readonly) const char *propertyEncode; ///<编码类型
@property (nonatomic, readonly) NSString *databaseName;     ///<字段名
@property (nonatomic, readonly) NSString *databaseType;     ///<字段类型
@property (nonatomic, assign) GYDBPropertyType type;        ///<属性类型

//基本类的prop对象,分别对应:NSString,NSMutableString,NSNumber,NSDate,NSData
+ (instancetype)stringProp;
+ (instancetype)numberProp;
+ (instancetype)dateProp;
+ (instancetype)dataProp;

+ (instancetype)propertyWithObjcProp:(objc_property_t)prop;

@end
