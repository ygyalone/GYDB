#iOS database framework based on sqlite3(基于sqlite3的iOS数据库存储框架)

在iOS开发中，如果使用到数据库来存储数据，使用比较多的是FMDB或者CoreData，或者直接使用sqlite3。但是各种配置比较麻烦，或者需要自己写sql语句。存储一个对象，为什么需要这么麻烦？如果使用GYDB，类似存储对象的操作只要写:

```
[obj gy_insert];
```
就能插入一条数据到表中，就是这么简单方便。觉得不错的话可以在github上星一下。

GitHub: [https://github.com/ygyalone](https://github.com/ygyalone)

Feedback: [ygy9916730@163.com](mailto:ygy9916730@163.com)

遇到问题欢迎issue或者邮件,感谢使用GYDB.
#描述(description)
> 1.采用分类的模式,方便基于NSObject的类或者对象的数据库操作.
> 
> 2.关于线程安全:所有数据库操作都放在一个并发量为1的操作队列中,保证多线程使用的安全.
> 
> 3.支持的数据类型有:

>* char, unsigned char, short, unsigned short, int, unsigned int.
>* long, unsigned long, long long, unsingned long long, float, double.
>* NSString.
>* NSNumber.
>* NSDate.
>* NSData.

#目录(index)
>* [安装(install)](#install_ID)
>* [基本配置(config)](#config_ID)
>* [表操作(table operate)](#tableOp_ID)
>* [插入(insert)](#insert_ID)
>* [删除(delete)](#delete_ID)
>* [查询(query)](#query_ID)
>* [修改(update)](#update_ID)
>* [保存(save)](#save_ID)
>* [其它操作(other)](#other_ID)
>* [链式条件配置(condition)](#condition_ID)

<a id="install_ID"></a>
#安装(install)
```
pod 'GYDB'
```
> 如果没有搜索到GYDB,请删除本地缓存后再安装:

```
rm ~/Library/Caches/CocoaPods/search_index.json
```

>注意:不使用pod安装的小伙伴需要手动添加libsqlite3.tbd的依赖

<a id="config_ID"></a>
#基本配置(config)
##通用配置
> 是否开启日志(默认开启):

```objc
//关闭日志
DBManager.openLog = NO;
```
> 设置异步回调时的队列,默认为manager的异步队列

```objc
//设置在主线程中回调block
DBManager.completionQueue = dispatch_get_main_queue();
```

>打开(创建)数据库:默认会打开(创建)Documents/gydb/gydb.sqlite路径下的数据库

```objc
[DBManager openDatabase:dbPath];
```

>关闭数据库

```objc
[DBManager closeDatabase:dbPath];
```

##存储配置
> 自定义主键值

```objc
- (NSString *)gy_customPrimaryKeyValue {
    return @"456";
}
```

> 自定义对象关联(返回自定义对象属性的类型)

```objc
+ (NSDictionary<NSString *,Class> *)gy_customClass {
    return @{@"bestFriend":[Person class],
             @"favoritePet":[Pet class]};
}
```

> 对象数组关联(返回数组中元素的类型,不管是自定义类型还是支持的NS类型,都需要返回)

```objc
+ (NSDictionary<NSString *,Class> *)gy_classInArray {
    return @{@"nickNames":[NSString class],
             @"favoriteNums":[NSNumber class],
             @"favoriteDates":[NSDate class],
             @"privateDatas":[NSData class],
             @"pets1":[Pet class],
             @"pets2":[Pet class]};
}
```
<a id="tableOp_ID"></a>
#表操作(table operate)
> 检查表是否存在

```objc
BOOL exist = [Person gy_tableExistsWithError:nil];
```

> 创建表

```objc
[Person gy_createTable];
```

> 删除表

```objc
[Person gy_dropTable];
```

> 更新表(只增加旧表没有的字段)

```objc
[Person gy_updateTable];
```
<a id="insert_ID"></a>
#插入(insert)
##插入单条数据
> 同步方法:

```objc
[person gy_insert];
```

>异步方法:

```objc
[person gy_insertWithCompletion:^(GYDBError *error) {
	if (error) {
		//succeed
	}else {
		//failed
	}
}];
```

##插入多条数据
> 同步方法:

```objc
GYDBError *error = [[GYDatabaseManager sharedManager] insertObjs:persons];
```

> 异步方法:

```objc
[DBManager insertObjs:persons completion:^(GYDBError *error) {
        
}];
```

<a id="delete_ID"></a>
#删除(delete)
##根据对象删除
>同步方法:

```objc
[person gy_delete];
```
>异步方法:

```objc
[person gy_deleteWithCompletion:^(GYDBError *error) {
        
}];
```
##根据类删除
>同步方法:

```objc
//删除Person表中所有数据
[Person gy_deleteAll]

//删除Person表中age小于79的行
[Person gy_deleteObjsWithCondition:DBCondition.Where_P(age).Lt(@79)];

```
>异步方法:

```objc
//删除Person表中所有的行
[Person gy_deleteAllWithCompletion:^(GYDBError *error) {
            
}];

//删除Person表中height大于等于100的行
[Person gy_deleteObjsWithCondition:DBCondition.Where_P(height).GtOrEq(@100) completion:^(GYDBError *error) {
            
}];
```
<a id="query_ID"></a>
#查询(query)
>同步方法:

```objc
//查询Person表中主键大于456的行,根据age逆序排序
[Person gy_queryObjsWithCondition:DBCondition.Where_PK().Gt(@"456").OrderBy_P(age).Descending() error:&error];
```

>异步方法:

```objc
//查询Person表中所有的行
[Person gy_queryObjsWithCondition:nil completion:^(NSArray *result, GYDBError *error) {
            
}];
```
<a id="update_ID"></a>
#修改(update)
>同步方法:

```objc
//更新除age之外的所有属性
[person gy_updateWithExcludeColumns:@[@"age"]];
```

>异步方法:

```objc
//更新所有属性
[person gy_updateWithExcludeColumns:nil completion:^(GYDBError *error) {
                
}];
```

<a id="save_ID"></a>
#保存(save)
>如果对象未入库,save方法等于insert方法.否则等于update方法.
>
>同步方法:

```objc
[obj gy_save];
```
>异步方法:

```objc
[obj gy_saveWithCompletion:^(GYDBError *error) {
        
}];
```

<a id="other_ID"></a>
#其它操作(other)
>获取当前打开的数据库路径,没有则返回nil

```objc
DBManager.databasePath;
```
>获取表中数据行数

```objc
//查询Person表中的数据行数
NSInteger rowCount1 = [Person gy_countWithCondition:nil error:&error];

//查询Person表中age大于等于24的数据行数
NSInteger rowCount2 = [Person gy_countWithCondition:DBCondition.Where_P(age).GtOrEq(@24) error:&error];
```

<a id="condition_ID"></a>
#链式条件配置(condition)
>使用链式语法能够方便地配置执行Sql操作时的条件.举例:

```objc
//查询name以Alone结尾或者age大于等于24,根据age降序排序的从索引0开始的10条数据...
[Person gy_queryObjsWithCondition:DBCondition.Where_P(name).Like(@"%Alone").Or_P(age).GtOrEq(@24).OrderBy_P(age).Descending().Limit(0,10) error:&error]
```
>详细说明见下表:

条件|说明|举例|参数类型
---|---|---|---
Where|筛选条件.传入属性名.|Where(@"age"):根据age筛选|NSString *
Where_P|筛选条件.和Where相同,会自动匹配selector,方便输入.|Where_P(age):根据age筛选|NSString *
Where_PK |筛选条件.匹配主键,等价Where(@"_id").|Where_PK():根据主键筛选|void
Eq|比较条件.相等.|Where_P(age).Eq(@24):age等于24|NSString * NSNumber *
Nq|比较条件.不相等.|Where_P(name).Nq(@"ygy"):name不等于ygy|NSString * NSNumber *
Lt|比较条件.小于.|Where_P(age).Lt(@24):age小于24|NSString * NSNumber *
Gt|比较条件.大于.|Where_P(age).Gt(@24):age大于24|NSString * NSNumber *
LtOrEq|比较条件.小于等于.|Where_P(age).LtOrEq(@24):age小于等于24|NSString * NSNumber *
GtOrEq|比较条件.大于等于.|Where_P(age).GtOrEq(@24):age大于等于24|NSString * NSNumber *
Like|通配符筛选条件.|Where_P(name).Like(@"%Alone"):根据通配符'%Alone'查询|NSString *
And|与条件.|Where_P(name).Like(@"%Alone").And(@"age").Gt(@17):name满足通配符匹配,并且age大于17|NSString *
And_P|与条件.和And相同,会自动匹配selector,方便输入.|Where_P(name).Like(@"%Alone").And_P(age).Gt(@17):name满足通配符匹配,并且age大于17|NSString *
Or|或条件.|Where_P(name).Like(@"%Alone").Or(@"age").Gt(@24):name满足通配符匹配,或者age大于24|NSString *
Or_P|或条件.和Or相同,会自动匹配selector,方便输入.|Where_P(name).Like(@"%Alone").Or(@"age").Gt(@24):name满足通配符匹配,或者age大于24|NSString *
OrderBy|排序条件.|OrderBy(age):根据age排序,默认为升序排序|NSString *
OrderBy_P|排序条件,和OrderBy相同,会自动匹配selector,方便输入.|OrderBy(age):根据age排序,默认为升序排序|NSString *
Ascending|升序排序条件|OrderBy_P(age).Ascending():根据age升序排序|void
Descending|降序排序条件|OrderBy_P(age).Descending():根据age降序排序|void
Limit|数量限制条件|Limit(0,10):结果集合中从索引0开始的10条数据|NSInteger(offset) NSInteger(len)

>更多详细介绍请参考NSObject+GYDB.h和GYDatabaseManager.h
