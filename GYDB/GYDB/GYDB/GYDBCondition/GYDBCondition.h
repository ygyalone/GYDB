//
//  GYDBCondition.h
//  GYDB
//
//  Created by GuangYu on 17/1/22.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>

#define P(_prop_)              (((void)(NO && ((void)(@selector(_prop_)), NO)), @#_prop_))

#define kColumnPK               @"_id"          ///<主键字段
#define DBCondition [GYDBCondition condition]
#define Where_PK() Where(kColumnPK)
#define Where_P(_prop_) Where(P(_prop_))        ///<匹配selector的where
#define And_P(_prop_) And(P(_prop_))            ///<匹配selector的and
#define Or_P(_prop_) Or(P(_prop_))              ///<匹配selector的or
#define OrderBy_P(_prop_) OrderBy(P(_prop_))    ///<匹配selector的orderBy

@class GYWhereCondition;
@class GYCompareCondition;
@class GYCompareOrderByCondition;
@class GYAndOrOrderByCondition;
@class GYOrderCondition;
@class GYLimitCondition;

@protocol conditionStringProtocol <NSObject>
@property (nonatomic, readonly) NSMutableString *conditionString;
@end

@protocol orderProtocol <NSObject>
@optional
@property (nonatomic, copy, readonly) GYLimitCondition* (^Ascending)();       ///<升序
@property (nonatomic, copy, readonly) GYLimitCondition* (^Descending)();      ///<降序
@end

@protocol orderByProtocol <NSObject>
@optional
@property (nonatomic, copy, readonly) GYOrderCondition *(^OrderBy)(NSString *column);   ///<根据某个属性排序
- (GYOrderCondition *(^)(NSString *))OrderBy_P;
@end

@protocol andOrProtocol <NSObject>
@optional
@property (nonatomic, copy, readonly) GYCompareCondition *(^And)(NSString *column);     ///<与条件
@property (nonatomic, copy, readonly) GYCompareCondition *(^Or)(NSString *column);      ///<或条件
- (GYCompareCondition *(^)(NSString *))And_P;
- (GYCompareCondition *(^)(NSString *))Or_P;
@end

@protocol compareProtocol <NSObject>
@optional
@property (nonatomic, copy, readonly) GYAndOrOrderByCondition *(^Eq)(id value);             ///<等于
@property (nonatomic, copy, readonly) GYAndOrOrderByCondition *(^Nq)(id value);             ///<不等于
@property (nonatomic, copy, readonly) GYAndOrOrderByCondition *(^Lt)(id value);             ///<大于
@property (nonatomic, copy, readonly) GYAndOrOrderByCondition *(^Gt)(id value);             ///<小于
@property (nonatomic, copy, readonly) GYAndOrOrderByCondition *(^LtOrEq)(id value);         ///<小于等于
@property (nonatomic, copy, readonly) GYAndOrOrderByCondition *(^GtOrEq)(id value);         ///<大于等于
@property (nonatomic, copy, readonly) GYAndOrOrderByCondition *(^Like)(NSString *wildcard); ///<通配符条件
@end

@protocol limitProtocol <NSObject>
@optional
@property (nonatomic, copy, readonly) id<conditionStringProtocol> (^Limit)(NSInteger offset, NSInteger len);  ///<分块
@end

@protocol whereProtocol <NSObject>
@optional
@property (nonatomic, copy, readonly) GYCompareCondition *(^Where)(NSString *column);
- (GYCompareCondition *(^)(NSString *))Where_P;
- (GYCompareCondition *(^)())Where_PK;
@end

@interface GYDBCondition : NSObject <conditionStringProtocol>
+ (GYWhereCondition *)condition;
@end

@interface GYWhereCondition : GYDBCondition <whereProtocol, orderByProtocol, limitProtocol>
@end

@interface GYCompareCondition : GYDBCondition <compareProtocol, limitProtocol>
@end

@interface GYCompareOrderByCondition : GYDBCondition <compareProtocol, orderByProtocol, limitProtocol>
@end

@interface GYAndOrOrderByCondition : GYDBCondition <andOrProtocol, orderByProtocol, limitProtocol>
@end

@interface GYOrderCondition : GYDBCondition <orderProtocol, limitProtocol>
@end

@interface GYLimitCondition : GYDBCondition <limitProtocol>
@end
