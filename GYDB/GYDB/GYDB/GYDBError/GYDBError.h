//
//  GYDBError.h
//  GYDB
//
//  Created by GuangYu on 17/2/26.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <Foundation/Foundation.h>

//errorCodes from sqlite3.h
typedef NS_ENUM(NSUInteger, GYDBErrorCode) {
    GYDBErrorCode_SQLITE_OK = 0,            /* Successful result */
    GYDBErrorCode_SQLITE_ERROR = 1,         /* SQL error or missing database */
    GYDBErrorCode_SQLITE_INTERNAL = 2,      /* Internal logic error in SQLite */
    GYDBErrorCode_SQLITE_PERM = 3,          /* Access permission denied */
    GYDBErrorCode_SQLITE_ABORT = 4,         /* Callback routine requested an abort */
    GYDBErrorCode_SQLITE_BUSY = 5,          /* The database file is locked */
    GYDBErrorCode_SQLITE_LOCKED = 6,        /* A table in the database is locked */
    GYDBErrorCode_SQLITE_NOMEM = 7,         /* A malloc() failed */
    GYDBErrorCode_SQLITE_READONLY = 8,      /* Attempt to write a readonly database */
    GYDBErrorCode_SQLITE_INTERRUPT = 9,     /* Operation terminated by sqlite3_interrupt()*/
    GYDBErrorCode_SQLITE_IOERR = 10,        /* Some kind of disk I/O error occurred */
    GYDBErrorCode_SQLITE_CORRUPT = 11,      /* The database disk image is malformed */
    GYDBErrorCode_SQLITE_NOTFOUND = 12,     /* Unknown opcode in sqlite3_file_control() */
    GYDBErrorCode_SQLITE_FULL = 13,         /* Insertion failed because database is full */
    GYDBErrorCode_SQLITE_CANTOPEN = 14,     /* Unable to open the database file */
    GYDBErrorCode_SQLITE_PROTOCOL = 15,     /* Database lock protocol error */
    GYDBErrorCode_SQLITE_EMPTY = 16,        /* Database is empty */
    GYDBErrorCode_SQLITE_SCHEMA = 17,       /* The database schema changed */
    GYDBErrorCode_SQLITE_TOOBIG = 18,       /* String or BLOB exceeds size limit */
    GYDBErrorCode_SQLITE_CONSTRAINT = 19,   /* Abort due to constraint violation */
    GYDBErrorCode_SQLITE_MISMATCH = 20,     /* Data type mismatch */
    GYDBErrorCode_SQLITE_MISUSE = 21,       /* Library used incorrectly */
    GYDBErrorCode_SQLITE_NOLFS = 22,        /* Uses OS features not supported on host */
    GYDBErrorCode_SQLITE_AUTH = 23,         /* Authorization denied */
    GYDBErrorCode_SQLITE_FORMAT = 24,       /* Auxiliary database format error */
    GYDBErrorCode_SQLITE_RANGE = 25,        /* 2nd parameter to sqlite3_bind out of range */
    GYDBErrorCode_SQLITE_NOTADB = 26,       /* File opened that is not a database file */
    GYDBErrorCode_SQLITE_NOTICE = 27,       /* Notifications from sqlite3_log() */
    GYDBErrorCode_SQLITE_WARNING = 28,      /* Warnings from sqlite3_log() */
    GYDBErrorCode_SQLITE_ROW = 100,         /* sqlite3_step() has another row ready */
    GYDBErrorCode_SQLITE_DONE = 101,        /* sqlite3_step() has finished executing */
};

@interface GYDBError : NSObject

@property (nonatomic, readonly) GYDBErrorCode code; ///<错误码
@property (nonatomic, readonly) NSString *message;  ///<提示

+ (instancetype)errorWithCode:(GYDBErrorCode)code message:(NSString *)message;

@end
