//
//  ViewController.m
//  GYDB
//
//  Created by GuangYu on 17/3/5.
//  Copyright © 2017年 YGY. All rights reserved.
//

#import "ViewController.h"
#import "GYDB.h"

@interface Person : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger age;
@end

@implementation Person

- (instancetype)init {
    if (self = [super init]) {
        _name = @"name";
        _age = arc4random()%200+1;
    }
    return self;
}

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //基本使用看单元测试
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
