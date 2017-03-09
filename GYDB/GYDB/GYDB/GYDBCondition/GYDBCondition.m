//
//  GYDBCondition.m
//  GYDB
//
//  Created by GuangYu on 17/1/22.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYDBCondition.h"
#import "GYDBSqlGenerator.h"

#define convert(_value_) [weakSelf convertToTextType:_value_]

@interface GYDBCondition () <whereProtocol, limitProtocol, compareProtocol, andOrProtocol, orderByProtocol, orderProtocol>

@end

@implementation GYDBCondition {
    NSMutableString *_conditionString;
    NSDictionary *_mapDic;
}

@synthesize Where = _Where;
@synthesize Limit = _Limit;
@synthesize Eq = _Eq;
@synthesize Nq = _Nq;
@synthesize Lt = _Lt;
@synthesize Gt = _Gt;
@synthesize LtOrEq = _LtOrEq;
@synthesize GtOrEq = _GtOrEq;
@synthesize Like = _Like;
@synthesize And = _And;
@synthesize Or = _Or;
@synthesize OrderBy = _OrderBy;
@synthesize Ascending = _Ascending;
@synthesize Descending = _Descending;

+ (GYWhereCondition *)condition {
    return [[GYWhereCondition alloc] init];
}

- (NSString *)convertToTextType:(id)value {
    NSString *convertString;
    if ([value isKindOfClass:[NSString class]]) {
        convertString = [NSString stringWithFormat:@"'%@'", value];
    }else {
        convertString = [value description];
    }
    return convertString;
}

- (NSMutableString *)conditionString {
    return _conditionString;
}

- (NSString *)columnConvert:(NSString *)column {
    //转换主键或者外键对应的数据库字段名字
    NSString *convertColumn = _mapDic[column];
    if (convertColumn) {
        return convertColumn;
    }
    return column;
}

- (instancetype)init {
    if (self = [super init]) {
        _conditionString = [NSMutableString string];
        _mapDic = @{@"gy_primaryKeyValue":kColumnPK,
                    @"gy_singleLinkID":kColumnSingleLinkID,
                    @"gy_multiLinkID":kColumnMultiLinkID};
        __weak typeof(self) weakSelf = self;
        
        //where
        _Where = ^(NSString *column) {
            if (column.length) {
                [weakSelf.conditionString appendString:@" where "];
                [weakSelf.conditionString appendString:[weakSelf columnConvert:column]];
            }
            return (GYCompareCondition *)weakSelf;
        };
        
        //limit
        _Limit = ^(NSInteger offset, NSInteger len) {
            [weakSelf.conditionString appendFormat:@" limit %ld,%ld ", offset, len];
            return weakSelf;
        };
        
        //compare
        _Eq = ^(id value) {
            if ([value description].length) {
                [weakSelf.conditionString appendString:@" = "];
                [weakSelf.conditionString appendString:convert(value)];
            }
            return (GYAndOrOrderByCondition *)weakSelf;
        };
        
        _Nq = ^(id value) {
            if ([value description].length) {
                [weakSelf.conditionString appendString:@" != "];
                [weakSelf.conditionString appendString:convert(value)];
            }
            return (GYAndOrOrderByCondition *)weakSelf;
        };
        
        _Lt = ^(id value ){
            if ([value description].length) {
                [weakSelf.conditionString appendString:@" < "];
                [weakSelf.conditionString appendString:convert(value)];
            }
            return (GYAndOrOrderByCondition *)weakSelf;
        };
        
        _Gt = ^(id value) {
            if ([value description].length) {
                [weakSelf.conditionString appendString:@" > "];
                [weakSelf.conditionString appendString:convert(value)];
            }
            return (GYAndOrOrderByCondition *)weakSelf;
        };
        
        _LtOrEq = ^(id value) {
            if ([value description].length) {
                [weakSelf.conditionString appendString:@" <= "];
                [weakSelf.conditionString appendString:convert(value)];
            }
            return (GYAndOrOrderByCondition *)weakSelf;
        };
        
        _GtOrEq = ^(id value) {
            if ([value description].length) {
                [weakSelf.conditionString appendString:@" >= "];
                [weakSelf.conditionString appendString:convert(value)];
            }
            return (GYAndOrOrderByCondition *)weakSelf;
        };
        
        _Like = ^(NSString *wildcard) {
            if ([wildcard description].length) {
                [weakSelf.conditionString appendString:@" like "];
                [weakSelf.conditionString appendString:[NSString stringWithFormat:@"'%@'", wildcard]];
            }
            return (GYAndOrOrderByCondition *)weakSelf;
        };
        
        //adn or
        _And = ^(NSString *column) {
            if (column.length) {
                [weakSelf.conditionString appendString:@" and "];
                [weakSelf.conditionString appendString:[weakSelf columnConvert:column]];
            }
            return (GYCompareCondition *)weakSelf;
        };
        
        _Or = ^(NSString *column) {
            if (column.length) {
                [weakSelf.conditionString appendString:@" or "];
                [weakSelf.conditionString appendString:[weakSelf columnConvert:column]];
            }
            return (GYCompareCondition *)weakSelf;
        };
        
        //orderBy
        _OrderBy = ^(id value) {
            if ([value description].length) {
                [weakSelf.conditionString appendString:@" order by "];
                [weakSelf.conditionString appendString:[value description]];
            }
            return (GYOrderCondition *)weakSelf;
        };
        
        //order
        _Ascending = ^() {
            [weakSelf.conditionString appendString:@" asc "];
            return (GYLimitCondition *)weakSelf;
        };
        
        _Descending = ^() {
            [weakSelf.conditionString appendString:@" desc "];
            return (GYLimitCondition *)weakSelf;
        };
    }
    return self;
}

@end

@implementation GYWhereCondition

@end

@implementation GYCompareCondition

@end

@implementation GYCompareOrderByCondition

@end


@implementation GYAndOrOrderByCondition

@end

@implementation GYOrderCondition

@end

@implementation GYLimitCondition

@end
