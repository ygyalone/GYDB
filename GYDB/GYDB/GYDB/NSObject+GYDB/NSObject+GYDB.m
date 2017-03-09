//
//  NSObject+GYDB.m
//  GYDB
//
//  Created by GuangYu on 17/1/18.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "NSObject+GYDB.h"
#import "GYDBSqlGenerator.h"
#import "GYDatabaseManager.h"
#import <objc/runtime.h>

@interface NSObject (GYDBStorageProtocol) <GYDBStorageProtocol>
- (void)setPrimaryKeyValue:(NSString *)primaryKeyValue;
- (void)setSingleLinkID:(NSString *)singleLinkID;
- (void)setMultiLinkID:(NSString *)multiLinkID;
@end

@implementation NSObject (GYDBStorageProtocol)
- (void)setPrimaryKeyValue:(NSString *)primaryKeyValue {
    objc_setAssociatedObject(self, @selector(setPrimaryKeyValue:), primaryKeyValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)setSingleLinkID:(NSString *)singleLinkID {
    objc_setAssociatedObject(self, @selector(setSingleLinkID:), singleLinkID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setMultiLinkID:(NSString *)multiLinkID {
    objc_setAssociatedObject(self, @selector(setMultiLinkID:), multiLinkID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSObject (GYDB)
#pragma mark - base
+ (NSDictionary<NSString *, Class> *)gy_customClass {
    return nil;
}

+ (NSDictionary<NSString *, Class> *)gy_classInArray{
    return nil;
}

- (NSString *)gy_primaryKeyValue {
    NSString *pk = objc_getAssociatedObject(self, @selector(setPrimaryKeyValue:));
    if (pk.length) {
        return pk;
    }
    return [self gy_customPrimaryKeyValue];
}
- (NSString *)gy_singleLinkID {
    return objc_getAssociatedObject(self, @selector(setSingleLinkID:));
}

- (NSString *)gy_multiLinkID {
    return objc_getAssociatedObject(self, @selector(setMultiLinkID:));
}

- (NSString *)gy_customPrimaryKeyValue {
    return nil;
}

#pragma mark - table
+ (BOOL)gy_tableExistsWithError:(GYDBError **)error {
    return [[GYDatabaseManager sharedManager] tableExistsForClazz:self error:error];
}
+ (GYDBError *)gy_createTable {
    return [[GYDatabaseManager sharedManager] createTableForClazz:self];
}
+ (GYDBError *)gy_dropTable {
    return [[GYDatabaseManager sharedManager] dropTableForClazz:self];
}
+ (GYDBError *)gy_updateTable {
    return [[GYDatabaseManager sharedManager] updateTableForClazz:self];
}

#pragma mark - count
+ (NSInteger)gy_countWithCondition:(GYDBCondition *)conditon error:(GYDBError **)error {
    return [[GYDatabaseManager sharedManager] rowCountForClazz:self condition:conditon error:error];
}

#pragma mark - save (insert or update)
- (GYDBError *)gy_save {
    return [[GYDatabaseManager sharedManager] saveObj:self];
}
- (void)gy_saveWithCompletion:(GYErrorBlock)completion {
    return [[GYDatabaseManager sharedManager] saveObj:self completion:completion];
}

#pragma mark - insert
- (GYDBError *)gy_insert {
    return [[GYDatabaseManager sharedManager] insertObj:self];
}
- (void)gy_insertWithCompletion:(GYErrorBlock)completion {
    return [[GYDatabaseManager sharedManager] insertObj:self completion:completion];
}

#pragma mark - delete
- (GYDBError *)gy_delete {
    return [[GYDatabaseManager sharedManager] deleteObj:self];
}
- (void)gy_deleteWithCompletion:(GYErrorBlock)completion {
    return [[GYDatabaseManager sharedManager] deleteObj:self completion:completion];
}

+ (GYDBError *)gy_deleteAll {
    return [[GYDatabaseManager sharedManager] deleteObjsWithClazz:self condition:nil];
}
+ (void)gy_deleteAllWithCompletion:(GYErrorBlock)completion {
    return [[GYDatabaseManager sharedManager] deleteObjsWithClazz:self condition:nil completion:completion];
}

+ (GYDBError *)gy_deleteObjsWithCondition:(GYDBCondition *)condition {
    return [[GYDatabaseManager sharedManager] deleteObjsWithClazz:self condition:condition];
}

+ (void)gy_deleteObjsWithCondition:(GYDBCondition * )condition completion:(GYErrorBlock)completion {
    return [[GYDatabaseManager sharedManager] deleteObjsWithClazz:self condition:condition completion:completion];
}

#pragma mark - query
+ (NSArray * )gy_queryObjsWithCondition:(GYDBCondition * )condition error:(GYDBError **)error {
    return [[GYDatabaseManager sharedManager] queryObjsForClazz:self condition:condition error:error];
}
+ (void)gy_queryObjsWithCondition:(GYDBCondition * )condition completion:(GYArrayBlock )completion {
    return [[GYDatabaseManager sharedManager] queryObjsForClazz:self condition:condition completion:completion];
}

#pragma mark - update
- (GYDBError *)gy_updateWithExcludeColumns:(NSArray<NSString *> * )excludeColumns {
    return [[GYDatabaseManager sharedManager] updateObj:self excludeColumns:excludeColumns];
}

- (void)gy_updateWithExcludeColumns:(NSArray<NSString *> * )excludeColumns completion:(GYErrorBlock)completion {
    return [[GYDatabaseManager sharedManager] updateObj:self excludeColumns:excludeColumns completion:completion];
}

@end
