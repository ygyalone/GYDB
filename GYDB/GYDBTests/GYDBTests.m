//
//  GYDBTests.m
//  GYDBTests
//
//  Created by GuangYu on 17/3/5.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GYDatabaseManager.h"
#import "NSObject+GYDB.h"

#pragma mark - TESTClass
@interface Pet : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSDate *birthday;
@property (nonatomic, assign) float weight;
@end

@implementation Pet

- (instancetype)init {
    if (self = [super init]) {
        _name = [NSString stringWithFormat:@"petName%d",arc4random()%20+1];
        _birthday = [NSDate dateWithTimeIntervalSinceNow:arc4random()%10000];
        _weight = arc4random()%300;
    }
    return self;
}

@end

@interface Person : NSObject

@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) double height;
@property (nonatomic, strong) NSNumber *weight;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDate *birthday;
@property (nonatomic, copy) NSMutableArray *pets1;
@property (nonatomic, copy) NSMutableArray *pets2;
@property (nonatomic, copy) NSArray<NSString *> *nickNames;
@property (nonatomic, copy) NSArray<NSNumber *> *favoriteNums;
@property (nonatomic, copy) NSArray<NSDate *> *favoriteDates;
@property (nonatomic, copy) NSArray<NSData *> *privateDatas;
@property (nonatomic, strong) Person *bestFriend;
@property (nonatomic, strong) Pet *favoritePet;

@end

@implementation Person
-(instancetype)init {
    if (self = [super init]) {
        _age = arc4random()%150+1;
        _height = arc4random()%200;
        _weight = @(arc4random()%100);
        _name = [NSString stringWithFormat:@"personName%d",arc4random()%20+1];
        _birthday = [NSDate dateWithTimeIntervalSinceNow:arc4random()%10000];
        _pets1 = [NSMutableArray arrayWithArray:@[[[Pet alloc] init],[[Pet alloc] init]]];
        _pets2 = [NSMutableArray arrayWithArray:@[[[Pet alloc] init],[[Pet alloc] init],[[Pet alloc] init]]];
        _nickNames = @[[NSString stringWithFormat:@"nickname%d",arc4random()%20+1],
                       [NSString stringWithFormat:@"nickname%d",arc4random()%20+1],
                       [NSString stringWithFormat:@"nickname%d",arc4random()%20+1]];
        _favoriteNums = @[@(100),@(100),@(arc4random()%100)];
        _favoriteDates = @[[NSDate dateWithTimeIntervalSinceNow:arc4random()%10000],
                           [NSDate dateWithTimeIntervalSinceNow:arc4random()%10000],
                           [NSDate dateWithTimeIntervalSinceNow:arc4random()%10000]];
        _privateDatas = @[[[NSString stringWithFormat:@"_privateDatas%d",arc4random()%20+1] dataUsingEncoding:NSUTF8StringEncoding],
                          [[NSString stringWithFormat:@"_privateDatas%d",arc4random()%20+1] dataUsingEncoding:NSUTF8StringEncoding],
                          [[NSString stringWithFormat:@"_privateDatas%d",arc4random()%20+1] dataUsingEncoding:NSUTF8StringEncoding],
                          [[NSString stringWithFormat:@"_privateDatas%d",arc4random()%20+1] dataUsingEncoding:NSUTF8StringEncoding],
                          [[NSString stringWithFormat:@"_privateDatas%d",arc4random()%20+1] dataUsingEncoding:NSUTF8StringEncoding]];
        _favoritePet = [[Pet alloc] init];
    }
    return self;
}

+ (NSDictionary<NSString *,Class> *)gy_customClass {
    return @{@"bestFriend":[Person class],
             @"favoritePet":[Pet class]};
}

+ (NSDictionary<NSString *,Class> *)gy_classInArray {
    return @{@"nickNames":[NSString class],
             @"favoriteNums":[NSNumber class],
             @"favoriteDates":[NSDate class],
             @"privateDatas":[NSData class],
             @"pets1":[Pet class],
             @"pets2":[Pet class]};
}
- (NSString *)gy_customPrimaryKeyValue {
    return nil;
    //return @"456";
}

@end


#pragma mark - TEST
@interface GYDBTests : XCTestCase

@end

@implementation GYDBTests
- (void)asyncTestWithBlock:(void(^)(XCTestExpectation *expectation))block {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    if (block) {
        block(expectation);
    }
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"async test failed:%@", error.domain);
    }];
}

#pragma mark - test insert
- (void)test_Insert {
    //sync
    Person *person = [[Person alloc] init];
    GYDBError *error = [person gy_insert];
    XCTAssertNil(error, @"sync insert failed:%@", error.message);
    
    //async
    [self asyncTestWithBlock:^(XCTestExpectation *expectation) {
        Person *p2 = [[Person alloc] init];
        [p2 gy_insertWithCompletion:^(GYDBError *error) {
            XCTAssertNil(error, @"async insert failed:%@", error.message);
            [expectation fulfill];
        }];
    }];
}

#pragma mark - test query
- (void)test_Query {
    //sync
    GYDBError *error = nil;
    [Person gy_queryObjsWithCondition:DBCondition.Where_PK().Gt(@"456").OrderBy_P(age).Descending() error:&error];
    XCTAssertNil(error, @"sync query failed:%@", error.message);
    
    //async
    [self asyncTestWithBlock:^(XCTestExpectation *expectation) {
        [Person gy_queryObjsWithCondition:nil completion:^(NSArray *result, GYDBError *error) {
            XCTAssertNil(error, @"async query failed:%@", error.message);
            [expectation fulfill];
        }];
    }];
}

#pragma mark - test update
- (void)test_SyncUpdate {
    GYDBError *error = nil;
    Person *person = [Person gy_queryObjsWithCondition:nil error:&error].firstObject;
    XCTAssertNil(error, @"sync query failed:%@", error.message);
    NSString *newName = @"newName_sync";
    NSInteger newAge = 1234;
    person.name = newName;
    person.age = newAge;
    
    error = [person gy_updateWithExcludeColumns:@[@"age"]];
    XCTAssertNil(error, @"sync update failed:%@", error.message);
    
    NSString *pk = person.gy_primaryKeyValue;
    person = [Person gy_queryObjsWithCondition:DBCondition.Where_PK().Eq(pk) error:&error].firstObject;
    XCTAssertNil(error, @"sync query failed:%@", error.message);
    
    XCTAssert([person.name isEqualToString:newName], @"update logic error");
    XCTAssert(person.age != newAge, @"update logic error");
}

- (void)test_AsyncUpdate {
    GYDBError *error = nil;
    __block Person *person = [Person gy_queryObjsWithCondition:nil error:&error].firstObject;
    XCTAssertNil(error, @"sync query failed:%@", error.message);
    NSString *newName = @"newName_aync";
    NSInteger newAge = 12345;
    person.name = newName;
    person.age = newAge;
    
    [self asyncTestWithBlock:^(XCTestExpectation *expectation) {
        if (person) {
            [person gy_updateWithExcludeColumns:@[@"age"] completion:^(GYDBError *error) {
                XCTAssertNil(error, @"sync update failed:%@", error.message);
                NSString *pk = person.gy_primaryKeyValue;
                person = [Person gy_queryObjsWithCondition:DBCondition.Where_PK().Eq(pk) error:&error].firstObject;
                XCTAssertNil(error, @"sync query failed:%@", error.message);
                
                XCTAssert([person.name isEqualToString:newName], @"update logic error");
                XCTAssert(person.age != newAge, @"update logic error");
                [expectation fulfill];
            }];
        }else {
            [expectation fulfill];
        }
    }];
}

#pragma mark - test save
- (void)test_Save {
    //sync
    __block GYDBError *error = nil;
    NSArray<Person *> *persons = [Person gy_queryObjsWithCondition:nil error:&error];
    XCTAssertNil(error, @"sync query failed:%@", error.message);
    [persons enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.name = @"save_name";
        error = [obj gy_save];
        XCTAssertNil(error, @"sync save failed:%@", error.message);
    }];
    
    //async
    [self asyncTestWithBlock:^(XCTestExpectation *expectation) {
        Person *newP = [[Person alloc] init];
        [newP gy_saveWithCompletion:^(GYDBError *error) {
            XCTAssertNil(error, @"async save failed:%@", error.message);
            [expectation fulfill];
        }];
    }];
}

#pragma mark - test delete
- (void)test_Delete {
    //sync
    GYDBError *error = nil;
    error = [Person gy_deleteAll];
    XCTAssertNil(error, @"sync deleteAll failed:%@", error.message);
    
    //async
    [self asyncTestWithBlock:^(XCTestExpectation *expectation) {
        [Person gy_deleteAllWithCompletion:^(GYDBError *error) {
            XCTAssertNil(error, @"async deleteAll failed:%@", error.message);
            [expectation fulfill];
        }];
    }];
}

- (void)test_DeleteWithCondition {
    //sync
    GYDBError *error = nil;
    error = [Person gy_deleteObjsWithCondition:DBCondition.Where_P(age).Lt(@79)];
    XCTAssertNil(error, @"sync deleteWithCondition failed:%@", error.message);
    
    //async
    [self asyncTestWithBlock:^(XCTestExpectation *expectation) {
        [Person gy_deleteObjsWithCondition:DBCondition.Where_P(height).GtOrEq(@100) completion:^(GYDBError *error) {
            XCTAssertNil(error, @"async deleteWithCondition failed:%@", error.message);
            [expectation fulfill];
        }];
    }];
}

#pragma mark - test other
- (void)test_Other {
    //count
    GYDBError *error = nil;
    [Person gy_countWithCondition:nil error:&error];
    XCTAssertNil(error, @"count failed:%@", error.message);
    
    //drop table
    error = [Pet gy_dropTable];
    XCTAssertNil(error, @"drop table failed:%@", error.message);
    
    //create table
    error = [Pet gy_createTable];
    XCTAssertNil(error, @"create table failed:%@", error.message);
    
    //update table
    error = [Pet gy_updateTable];
    XCTAssertNil(error, @"update table failed:%@", error.message);
    
    //completionQueue
    [self asyncTestWithBlock:^(XCTestExpectation *expectation) {
        [GYDatabaseManager sharedManager].completionQueue = dispatch_get_main_queue();
        [Person gy_queryObjsWithCondition:nil completion:^(NSArray *result, GYDBError *error) {
            XCTAssert([NSThread currentThread] == [NSThread mainThread], @"set completionQueue failed");
            [expectation fulfill];
        }];
    }];
}

@end
