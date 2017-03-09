//
//  GYDatabaseManager.m
//  GYDB
//
//  Created by GuangYu on 17/1/15.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "GYDatabaseManager.h"
#import <objc/runtime.h>
#import <sqlite3.h>
#import "NSObject+GYExtension.h"
#import "NSObject+GYDB.h"
#import "GYDBSqlGenerator.h"
#import "GYDBErrorGenerator.h"
#import "GYDBQueryHandler.h"
#import "GYDBUtil.h"

#define NotNullBoolBlock(_block_)   (_block_?_block_:^(BOOL result){})

@interface GYDatabaseManager ()

@property (nonatomic, readonly) NSString *defaultDatabasePath;
@property (nonatomic, assign) sqlite3 *database;
//线程安全queue,所有sql操作都放在queue中执行
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation GYDatabaseManager {
    BOOL _inTransaction;
}
@synthesize databasePath = _databasePath;

+ (instancetype)sharedManager {
    static GYDatabaseManager *sharedManager = nil;
    if (sharedManager) {
        return sharedManager;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedManager) {
            sharedManager = [[self alloc] init];
            [sharedManager openDatabase:sharedManager.defaultDatabasePath];
        }
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _openLog = YES;
    }
    return self;
}

- (void)dealloc {
    [self closeDB];
}

#pragma mark - databasePath
- (NSString *)defaultDatabasePath {
    NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [docDir stringByAppendingPathComponent:@"gydb/gydb.sqlite"];
}

- (void)createDirIfNotExists:(NSString *)filePath {
    NSString *dirPath = [filePath stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:dirPath]) {
        [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - database
- (GYDBError *)openDatabase:(NSString *)dbPath {
    DBLOG(@"databasePath:%@", dbPath);
    if ([self.databasePath isEqualToString:dbPath]) {
        return nil;
    }
    [self createDirIfNotExists:dbPath];
    GYDBError *error = [self closeDB];
    if (error) {
        return error;
    }
    
    error = [self openDB:dbPath];
    if (!error) {
        _databasePath = dbPath;
    }
    return error;
}

- (GYDBError *)closeDatabase:(NSString *)dbPath {
    if (![self.databasePath isEqualToString:dbPath]) {
        return nil;
    }
    
    GYDBError *error = [self closeDB];
    if (!error) {
        _databasePath = nil;
    }
    return error;
}

- (GYDBError *)openDB:(NSString *)dbPath {
    return [self exeSyncronizedWithErrorBlock:^id{
        if (_database && [_databasePath isEqualToString:dbPath]) {
            return nil;
        }
        if(sqlite3_open(dbPath.UTF8String, &_database) != SQLITE_OK) {
            sqlite3_close(_database);
            _database = nil;
            DBLOG(@"open database:%@ failed!\n", dbPath);
            return [GYDBError errorWithCode:GYDBErrorCode_SQLITE_CANTOPEN message:@"Unable to open the database file"];
        }
        return nil;
    } completion:nil];
}

- (GYDBError *)closeDB {
    return [self exeSyncronizedWithErrorBlock:^id{
        if (sqlite3_close(_database) != SQLITE_OK) {
            DBLOG(@"close database:%@ failed!\n", self.databasePath);
            return [GYDBError errorWithCode:GYDBErrorCode_SQLITE_ERROR message:@"Unable to close the database file"];
        }
        _database = nil;
        return nil;
    } completion:nil];
}

#pragma mark - operationQueue
- (NSOperationQueue *)operationQueue {
    @synchronized (self) {
        if (!_operationQueue) {
            _operationQueue = [[NSOperationQueue alloc] init];
            _operationQueue.maxConcurrentOperationCount = 1;
        }
    }
    return _operationQueue;
}

- (void)exeInQueueSynchronized:(BOOL)sync block:(void(^)())block{
    if ([[NSOperationQueue currentQueue] isEqual:self.operationQueue]) {
        if (block) {
            block();
        }
    }else {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:block];
        [self.operationQueue addOperation:operation];
        if (sync) {
            [operation waitUntilFinished];
        }
    }
}

- (id)exeSyncronizedWithErrorBlock:(id __nullable(^)())block completion:(GYErrorBlock)completion {
    __block id result = nil;
    [self exeInQueueSynchronized:!completion block:^{
        result = block();
        if (completion) {
            if (_completionQueue) {
                dispatch_sync(_completionQueue, ^{
                    completion(result);
                });
            }else {
                completion(result);
            }
        }
    }];
    return result;
}

- (id)exeSyncronizedWithBoolBlock:(id __nullable(^)())block completion:(void (^)(BOOL result))completion {
    __block id result = nil;
    [self exeInQueueSynchronized:!completion block:^{
        result = block();
        if (completion) {
            if (_completionQueue) {
                dispatch_sync(_completionQueue, ^{
                    completion(result);
                });
            }else {
                completion(result);
            }
        }
    }];
    return result;
}

- (id)exeSyncronizedWithIDBlock:(id __nullable(^)())block completion:(void (^)(id result))completion {
    __block id result = nil;
    [self exeInQueueSynchronized:!completion block:^{
        result = block();
        if (completion) {
            if (_completionQueue) {
                dispatch_sync(_completionQueue, ^{
                    completion(result);
                });
            }else {
                completion(result);
            }
        }
    }];
    return result;
}

- (id)exeSyncronizedWithArrayBlock:(id __nullable(^)())block completion:(GYArrayBlock)completion {
    __block id result = nil;
    [self exeInQueueSynchronized:!completion block:^{
        result = block();
        if (completion) {
            if (_completionQueue) {
                dispatch_sync(_completionQueue, ^{
                    completion(result, DBCurrentError);
                });
            }else {
                completion(result, DBCurrentError);
            }
        }
    }];
    return result;
}

#pragma mark - transaction
//sql操作放在事物中，防止破坏原始数据，同时提高执行速度
- (void)beginTransaction {
    if (_database && !_inTransaction) {
        sqlite3_stmt *stmt;
        if(sqlite3_prepare_v2(_database, "begin transaction", -1, &stmt, NULL) == SQLITE_OK) {
            if(sqlite3_step(stmt) == SQLITE_DONE) {
                _inTransaction = YES;
            }
        }
        sqlite3_finalize(stmt);
    }
}

- (void)commitTransaction {
    if (_database && _inTransaction) {
        sqlite3_stmt *stmt;
        if(sqlite3_prepare_v2(_database, "commit transaction", -1, &stmt, NULL) == SQLITE_OK) {
            if(sqlite3_step(stmt) == SQLITE_DONE) {
                _inTransaction = NO;
            }
        }
        sqlite3_finalize(stmt);
    }
}

- (void)rollbackTransaction {
    if (_database && _inTransaction) {
        sqlite3_stmt *stmt;
        if(sqlite3_prepare_v2(_database, "rollback transaction", -1, &stmt, NULL) == SQLITE_OK) {
            if(sqlite3_step(stmt) == SQLITE_DONE) {
                _inTransaction = NO;
            }
        }
        sqlite3_finalize(stmt);
    }
}

#pragma mark - count
- (NSInteger)rowCountForClazz:(Class)clazz
                    condition:(GYDBCondition *)conditon
                        error:(GYDBError **)error {
    return [[self exeSyncronizedWithIDBlock:^id _Nullable{
        if (![self tableExistsForClazz:clazz error:error]) {
            return @(0);
        }
        
        GYSql *sql = [GYDBSqlGenerator sqlForRowCountWithClazz:clazz condition:conditon];
        sqlite3_stmt *stmt;
        if (DBUpdateError(_database, sqlite3_prepare_v2(_database, sql.sqlString.UTF8String, -1, &stmt, NULL), SQLITE_OK)) {
            if (DBUpdateError(_database, sqlite3_step(stmt), SQLITE_ROW)) {
                NSInteger rowCount = sqlite3_column_int(stmt, 0);
                sqlite3_finalize(stmt);
                return @(rowCount);
            }
        }
        sqlite3_finalize(stmt);
        if (error) {
            *error = DBCurrentError;
        }
        return @(0);
    } completion:nil] integerValue];
}

#pragma mark - table
- (BOOL)tableExistsForClazz:(Class)clazz error:(GYDBError **)error {
    return [[self exeSyncronizedWithBoolBlock:^id{
        sqlite3_stmt *stmt;
        NSString *tableName = [clazz gy_className];
        if (DBUpdateError(_database, sqlite3_prepare_v2(_database, "select sql from sqlite_master where type = 'table' and name = ?", -1, &stmt, NULL), SQLITE_OK)) {
            [GYDBUtil bindObj:tableName toColumn:1 inStatement:stmt];
            if (DBUpdateError(_database, sqlite3_step(stmt), SQLITE_ROW)) {
                sqlite3_finalize(stmt);
                if (error) {
                    *error = DBCurrentError;
                }
                return @(YES);
            }
            sqlite3_finalize(stmt);
        }
        if (error) {
            *error = DBCurrentError;
        }
        return @(NO);
    } completion:nil] boolValue];
}

- (GYDBError *)createTableForClazz:(Class)clazz {
    return [self exeSyncronizedWithErrorBlock:^id{
        GYDBError *error = [self openDB:self.databasePath];
        if (error) return error;
        
        __block char *ERROR;
        __block BOOL success = YES;
        NSArray<GYSql *> *sqls = [GYDBSqlGenerator sqlsForCreateTableWithClazz:clazz];
        [sqls enumerateObjectsUsingBlock:^(GYSql * _Nonnull sql, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!DBUpdateError(_database, sqlite3_exec(_database, [sql.sqlString UTF8String], NULL, NULL, &ERROR), SQLITE_OK)){
                success = NO;
                *stop = YES;
            }
        }];
        if (!success) {
            DBLOG(@"create table(%@) failed:%s\n", [clazz gy_className], ERROR);
        }
        return DBCurrentError;
    } completion:nil];
}

- (GYDBError *)dropTableForClazz:(Class)clazz {
    return [self exeSyncronizedWithErrorBlock:^id{
        NSString *tableName = [clazz gy_className];
        __block char *ERROR;
        NSString *sqlString = [NSString stringWithFormat:@"drop table if exists %@", tableName];
        if(!DBUpdateError(_database, sqlite3_exec(_database, [sqlString UTF8String], NULL, NULL, &ERROR), SQLITE_OK)) {
            DBLOG(@"drop table(%@) failed:%s\n", tableName, ERROR);
        }
        return DBCurrentError;
    } completion:nil];
}

- (GYDBError *)updateTableForClazz:(Class)clazz {
    return [self exeSyncronizedWithErrorBlock:^id{
        GYDBError *error = [self openDB:self.databasePath];
        if (error) return error;
        
        //获取已有字段
        NSMutableArray *oldColumns = [NSMutableArray array];
        GYSql *getColumnsSql = [GYDBSqlGenerator sqlForTableColumnsWithClazz:clazz];
        sqlite3_stmt *stmt;
        if (DBUpdateError(_database, sqlite3_prepare_v2(_database, getColumnsSql.sqlString.UTF8String, -1, &stmt, NULL), SQLITE_OK)) {
            while (DBUpdateError(_database, sqlite3_step(stmt), SQLITE_ROW)) {
                NSString *oldColumn = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 1)];
                [oldColumns addObject:oldColumn];
            }
            sqlite3_finalize(stmt);
            
            //追加新字段
            NSArray<GYSql *> *updateTableSqls = [GYDBSqlGenerator sqlsForUpdateTableWithClazz:clazz oldColumns:oldColumns];
            __block char *Error;
            __block BOOL success = YES;
            [updateTableSqls enumerateObjectsUsingBlock:^(GYSql * _Nonnull sql, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!DBUpdateError(_database, sqlite3_exec(_database, sql.sqlString.UTF8String, NULL, NULL, &Error), SQLITE_OK)) {
                    success = NO;
                    *stop = YES;
                }
            }];
            return DBCurrentError;
        }
        sqlite3_finalize(stmt);
        return DBCurrentError;
    } completion:nil];
}

#pragma mark - save
- (GYDBError *)saveObj:(id)obj {
    return [self saveObj:obj withCompletion:nil];
}

- (void)saveObj:(id)obj completion:(GYErrorBlock)completion {
    [self saveObj:obj withCompletion:completion];
}

- (GYDBError *)saveObj:(id)obj withCompletion:(GYErrorBlock)completion {
    return [self exeSyncronizedWithErrorBlock:^id _Nullable{
        NSString *pk = [obj gy_primaryKeyValue];
        if (!pk.length) {
            return [self insertObj:obj];
        }else {
            GYDBCondition *condition = [GYDBCondition condition].Where(kColumnPK).Eq([obj gy_primaryKeyValue]);
            GYDBError *error;
            id old = [self queryObjsForClazz:[obj class] condition:condition error:&error].lastObject;
            if (error) return error;
            
            if (old) {
                return [self updateObj:obj excludeColumns:nil];
            }else {
                return [self insertObj:obj];
            }
        }
    } completion:completion];
}

#pragma mark - insert
- (GYDBError *)insertObj:(id)obj {
    return [self insertObj:obj inTransaction:YES completion:nil];
}

- (GYDBError *)insertObjNoTransaction:(id)obj {
    return [self insertObj:obj inTransaction:NO completion:nil];
}

- (void)insertObj:(id)obj completion:(GYErrorBlock)completion {
    [self insertObj:obj inTransaction:YES completion:completion];
}

- (GYDBError *)insertObj:(id)obj inTransaction:(BOOL)inTransaction completion:(GYErrorBlock)completion {
    return [self exeSyncronizedWithErrorBlock:^id{
        GYDBError *error = [self openDB:self.databasePath];
        if (error)  return error;
        
        //表不存在,建表
        if(![self tableExistsForClazz:[obj class] error:&error]) {
            if (!error) error = [self createTableForClazz:[obj class]];
        }
        if (error)  return error;
        
        if (inTransaction) {
            [self beginTransaction];
        }
        __block BOOL success = YES;
        NSArray<GYSql *> *sqls = [GYDBSqlGenerator sqlsForInsertObj:obj];
        [sqls enumerateObjectsUsingBlock:^(GYSql * _Nonnull sql, NSUInteger idx, BOOL * _Nonnull stop) {
            sqlite3_stmt *stmt;
            if(DBUpdateError(_database, sqlite3_prepare_v2(_database, [sql.sqlString UTF8String], -1, &stmt, NULL), SQLITE_OK)) {
                for (int i = 0; i < sql.args.count; i++) {
                    [GYDBUtil bindObj:sql.args[i] toColumn:(unsigned int)(i+1) inStatement:stmt];
                }
                success = DBUpdateError(_database, sqlite3_step(stmt), SQLITE_DONE);
                if (!success) {
                    *stop = YES;
                }
            }else {
                success = NO;
                *stop = YES;
            }
            sqlite3_finalize(stmt);
        }];
        if (inTransaction) {
            if (success) {
                [self commitTransaction];
            }else {
                [self rollbackTransaction];
            }
        }
        return DBCurrentError;
    } completion:completion];
}

- (GYDBError *)insertObjs:(NSArray *)objs {
    return [self insertObjs:objs withCompletion:nil];
}

- (void)insertObjs:(NSArray *)objs completion:(GYErrorBlock)completion {
    [self insertObjs:objs withCompletion:completion];
}

- (GYDBError *)insertObjs:(NSArray *)objs withCompletion:(GYErrorBlock)completion {
    return [self exeSyncronizedWithErrorBlock:^id _Nullable{
        __block GYDBError *error;
        [self beginTransaction];
        [objs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            error = [self insertObjNoTransaction:obj];
            if (error) {
                *stop = YES;
            }
        }];
        if (error) {
            [self rollbackTransaction];
        }else {
            [self commitTransaction];
        }
        return error;
    } completion:completion];
}

#pragma mark - delete
- (GYDBError *)deleteObj:(id)obj {
    return [self deleteObj:obj inTransaction:YES completion:nil];
}

- (GYDBError *)deleteObjNoTransaction:(id)obj {
    return [self deleteObj:obj inTransaction:NO completion:nil];
}

- (void)deleteObj:(id)obj completion:(GYErrorBlock)completion {
    [self deleteObj:obj inTransaction:YES completion:completion];
}

- (GYDBError *)deleteObj:(id)obj inTransaction:(BOOL)inTransaction completion:(GYErrorBlock)completion {
    return [self exeSyncronizedWithErrorBlock:^id _Nullable{
        GYDBError *error = [self openDB:self.databasePath];
        if (error)  return error;
        
        if (inTransaction) {
            [self beginTransaction];
        }
        __block BOOL success = YES;
        NSArray<GYSql *> *sqls = [GYDBSqlGenerator sqlsForDeleteObj:obj];
        [sqls enumerateObjectsUsingBlock:^(GYSql * _Nonnull sql, NSUInteger idx, BOOL * _Nonnull stop) {
            sqlite3_stmt *stmt;
            if (DBUpdateError(_database, sqlite3_prepare_v2(_database, sql.sqlString.UTF8String, -1, &stmt, NULL), SQLITE_OK)) {
                success = DBUpdateError(_database, sqlite3_step(stmt), SQLITE_DONE);
            }
            sqlite3_finalize(stmt);
            if (!success) {
                *stop = YES;
            }
        }];
        if (inTransaction) {
            if (success) {
                [self commitTransaction];
            }else {
                [self rollbackTransaction];
            }
        }
        return DBCurrentError;
    } completion:completion];
}

- (GYDBError *)deleteObjsWithClazz:(Class)clazz condition:(GYDBCondition * _Nullable)condition {
    return [self deleteObjsWithClazz:clazz withCondition:condition completion:nil];
}

- (void)deleteObjsWithClazz:(Class)clazz
                 condition:(GYDBCondition * _Nullable)condition
                completion:(GYErrorBlock _Nullable)completion {
    [self deleteObjsWithClazz:clazz withCondition:condition completion:completion];
}

- (GYDBError *)deleteObjsWithClazz:(Class)clazz
                     withCondition:(GYDBCondition * _Nullable)condition
                        completion:(GYErrorBlock _Nullable)completion {
    return [self exeSyncronizedWithErrorBlock:^id _Nullable{
        __block GYDBError *error;
        NSArray *objs = [self queryObjsForClazz:clazz condition:condition error:&error];
        if (error) return error;
        
        [self beginTransaction];
        [objs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            error = [self deleteObjNoTransaction:obj];
            if (error) {
                *stop = YES;
            }
        }];
        if (!error) {
            [self commitTransaction];
        }else {
            [self rollbackTransaction];
        }
        return error;
    } completion:completion];
}

#pragma mark - query
- (NSArray *)queryObjsForClazz:(Class)clazz
                      condition:(GYDBCondition * )condition
                          error:(GYDBError **)error {
    NSArray *objs = [self queryObjsForClazz:clazz withCondition:condition completion:nil];
    if (error) {
        *error = DBCurrentError;
    }
    return objs;
}

- (void)queryObjsForClazz:(Class)clazz
                condition:(GYDBCondition *)condition
               completion:(GYArrayBlock _Nullable)completion {
    [self queryObjsForClazz:clazz withCondition:condition completion:completion];
}

- (NSArray *)queryObjsForClazz:(Class)clazz
                            withCondition:(GYDBCondition *)condition
                           completion:(GYArrayBlock)completion {
    return [self exeSyncronizedWithArrayBlock:^id _Nullable{
        if (![self tableExistsForClazz:clazz error:nil]) {
            DBLOG(@"table(%@) not exists", [clazz gy_className]);
            return nil;
        }
        //query handler return error
        return [GYDBQueryHandler queryObjsWithClazz:clazz condition:condition database:_database];
    } completion:completion];
}

#pragma mark - update
- (GYDBError *)updateObj:(id)obj excludeColumns:(NSArray<NSString *> *)excludeColumns {
    return [self updateObj:obj excludeColumns:excludeColumns withCompletion:nil];
}

- (void)updateObj:(id)obj
   excludeColumns:(NSArray<NSString *> *)excludeColumns
       completion:(GYErrorBlock)completion {
    [self updateObj:obj excludeColumns:excludeColumns withCompletion:completion];
}

- (GYDBError *)updateObj:(id)obj
   excludeColumns:(NSArray<NSString *> *)excludeColumns
   withCompletion:(GYErrorBlock)completion {
    return [self exeSyncronizedWithErrorBlock:^id _Nullable{
        GYDBCondition *condition = [GYDBCondition condition].Where(kColumnPK).Eq([obj gy_primaryKeyValue]);
        GYDBError *error;
        id old = [self queryObjsForClazz:[obj class] condition:condition error:&error].lastObject;
        if (error) return error;
        
        [excludeColumns enumerateObjectsUsingBlock:^(NSString * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj setValue:[old valueForKey:prop] forKey:prop];
        }];
        [obj setPrimaryKeyValue:[old gy_primaryKeyValue]];
        
        error = [self deleteObj:old];
        if (!error) {
            error = [self insertObj:obj];
        }
        return error;
    } completion:completion];
}

- (GYDBError *)updateObjs:(NSArray *)objs excludeColumns:(NSArray<NSString *> *)excludeColumns {
    return [self updateObjs:objs excludeColumns:excludeColumns withCompletion:nil];
}

- (void)updateObjs:(NSArray *)objs
    excludeColumns:(NSArray<NSString *> *)excludeColumns
        completion:(GYErrorBlock)completion {
    [self updateObjs:objs excludeColumns:excludeColumns withCompletion:completion];
}

- (GYDBError *)updateObjs:(NSArray *)objs
    excludeColumns:(NSArray<NSString *> *)excludeColumns
    withCompletion:(GYErrorBlock)completion {
    return [self exeSyncronizedWithErrorBlock:^id _Nullable{
        __block GYDBError *error;
        [self beginTransaction];
        [objs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            error = [self updateObj:obj excludeColumns:excludeColumns];
            if (error) {
                *stop = YES;
            }
        }];
        if (error) {
            [self rollbackTransaction];
        }else {
            [self commitTransaction];
        }
        return error;
    } completion:completion];
}

@end

