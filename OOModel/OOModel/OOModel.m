//
//  OOModel.m
//  OOModel
//

#import "OOModel.h"
#import "OODatabase.h"
#import "objc/runtime.h"

static OODatabase *OOModelDatabase=nil;
static NSTimeInterval OOModelDatabaseOpenTime=-1;

#define OOSelectSql(table,sql) [NSString stringWithFormat:@"select * from %@ where %@",table,sql]
#define OODeleteSql(table,sql) [NSString stringWithFormat:@"delete from %@ where %@",table,sql]

inline static NSString* _columnTypeWithType(OODatabaseColumnType type) {
    NSString *columnType=nil;
    switch (type) {
        case OODatabaseColumnTypeText:
            columnType=@"text";
            break;
        case OODatabaseColumnTypeInteger:
            columnType=@"integer";
            break;
        case OODatabaseColumnTypeReal:
            columnType=@"real";
            break;
        case OODatabaseColumnTypeBlob:
            columnType=@"blob";
            break;
        default:
            assert(NO);
            break;
    }
    return columnType;
}

@implementation OOModel

#pragma mark --
#pragma mark -- init
+ (NSArray *)modelsWithDictionaries:(NSArray*)dictionaries{
    NSMutableArray *models=[NSMutableArray array];
    for (NSDictionary * dictionary in dictionaries){
        id model = [self.class modelWithDictionary:dictionary];
        if (model) {
            [models addObject:model];
        }
    }
    return models;
}

+ (instancetype)modelWithDictionary:(NSDictionary*)dictionary{
    return [[self alloc]initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary{
    self=[self init];
    if (self) {
        if (![self mergeWithDictionary:dictionary]) {
            self=nil;
        }
    }
    return self;
}

#pragma mark --
#pragma mark -- merge

- (BOOL)mergeWithDictionary:(NSDictionary*)dictionary{
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:NSNull.class]) {
            __autoreleasing id validateObj=obj;
            NSError *error=nil;
            if ([self validateValue:&validateObj forKey:key error:&error]) {
                [self setValue:validateObj forKey:key];
            }else{
                OOModelLog(@"%@",error);
            }
        }
    }];
    return YES;
}
- (BOOL)mergeWithModel:(OOModel*)model{
    [self mergeWithDictionary:[model dictionary]];
    return YES;
}

#pragma mark --
#pragma mark -- override
+ (void)load{
    [super load];
}
#pragma mark --
#pragma mark -- enumerate keys

+ (void)_enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
    Class class = self;
    BOOL stop = NO;
    while (!stop && ![class isEqual:OOModel.class]) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(class, &count);
        class = class.superclass;
        if (properties == NULL) {
            continue;
        }
        for (unsigned i = 0; i < count; i++) {
            objc_property_t property=properties[i];
            block(property, &stop);
            if (stop) {
                break;
            }
        }
        free(properties);
    }
}

#pragma mark --
#pragma mark -- getter

+ (NSArray *)propertyKeys {
    NSMutableArray *cachedKeys = objc_getAssociatedObject(self, @selector(propertyKeys));
    if (!cachedKeys) {
        cachedKeys = [NSMutableArray array];
        [self _enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
            @autoreleasepool {
                NSString *key = @(property_getName(property));
                NSString * propertyAttributesString=[[NSString alloc] initWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
                NSArray *propertyAttributes=[propertyAttributesString componentsSeparatedByString:@","];
                __block BOOL filtered=NO;
                [propertyAttributes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isEqualToString:@"R"]) {
                        filtered=YES;
                        *stop=YES;
                    }
                }];
                if (!filtered) {
                    [cachedKeys addObject:key];
                }
            }
        }];
        objc_setAssociatedObject(self, @selector(propertyKeys), cachedKeys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cachedKeys;
}

- (NSDictionary*)dictionary{
    return [self dictionaryWithValuesForKeys:[self.class propertyKeys]];
}

- (NSString*)description{
    return [[self dictionary] description];
}

@end

@implementation OOModel (OOJsonSerializing)

#pragma mark --
#pragma mark -- init

+ (NSArray *)modelsWithJsonDictionaries:(NSArray*)jsonDictionaries{
    NSMutableArray *models=[NSMutableArray array];
    for (NSDictionary * jsonDictionary in jsonDictionaries){
        id model = [self.class modelWithJsonDictionary:jsonDictionary];
        if (model) {
            [models addObject:model];
        }
    }
    return models;
}

+ (instancetype)modelWithJsonDictionary:(NSDictionary*)jsonDictionary{
    return [[self alloc]initWithJsonDictionary:jsonDictionary];
}

- (instancetype)initWithJsonDictionary:(NSDictionary*)jsonDictionary{
    self=[self init];
    if (self) {
        [self mergeWithJsonDictionary:jsonDictionary];
    }
    return self;
}

#pragma mark --
#pragma mark -- merge

- (BOOL)mergeWithJsonDictionary:(NSDictionary *)jsonDictionary{
    return [self mergeWithDictionary:[self.class _dictionaryWithJsonDictionary:jsonDictionary]];
}

#pragma mark --
#pragma mark -- getter

+ (NSString*)propertyKeyForKeyPath:(NSString*)keyPath{
    return [self _propertyKeysByKeyPath][keyPath];
}

+ (NSString*)keyPathForPropertyKey:(NSString*)propertyKey{
    return [self _keyPathsByPropertyKey][propertyKey];
}

+ (id)valueWithJsonValue:(id)value forPropertyKey:(NSString *)propertyKey{
    NSValueTransformer *valueTransformer=[self _jsonValueTransformerForKey:propertyKey];
    if (valueTransformer) {
        return [valueTransformer transformedValue:value];
    }
    return value;
}

+ (id)jsonValueWithValue:(id)value forPropertyKey:(NSString*)propertyKey{
    NSValueTransformer *valueTransformer=[self _jsonValueTransformerForKey:propertyKey];
    if (valueTransformer) {
        return [valueTransformer reverseTransformedValue:value];
    }
    return value;
}

- (NSDictionary*)jsonDictionary{
    return [self.class _jsonDictionaryWithDictionary:[self dictionary]];
}

+ (NSDictionary*)_jsonDictionaryWithDictionary:(NSDictionary*)dictionary{
    NSMutableDictionary *jsonDictionary=[NSMutableDictionary dictionary];
    if ([dictionary isKindOfClass:NSDictionary.class]) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, id  _Nonnull obj, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString *keyPath=[self _keyPathsByPropertyKey][propertyKey];
                id jsonValue=[self jsonValueWithValue:obj forPropertyKey:propertyKey];
                if (jsonValue) {
                    [jsonDictionary setObject:jsonValue forKey:keyPath];
                }
            }
        }];
    }
    return jsonDictionary;
}
+ (NSDictionary*)_dictionaryWithJsonDictionary:(NSDictionary*)jsonDictionary{
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    if ([jsonDictionary isKindOfClass:NSDictionary.class]) {
        [jsonDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull keyPath, id  _Nonnull jsonValue, BOOL * _Nonnull stop) {
            @autoreleasepool {
                id  propertyKey=[self _propertyKeysByKeyPath][keyPath];
                if (propertyKey&&![jsonValue isKindOfClass:NSNull.class]) {
                    id value=[self.class valueWithJsonValue:jsonValue forPropertyKey:propertyKey];
                    if (value) {
                        [dictionary setObject:value forKey:propertyKey];
                    }
                }
            }
        }];
    }
    return dictionary;
}

+ (NSDictionary*)_keyPathsByPropertyKey{
    NSDictionary * keyPathsByPropertyKey=objc_getAssociatedObject(self, @selector(_keyPathsByPropertyKey));
    if (!keyPathsByPropertyKey) {
        keyPathsByPropertyKey=[self.class jsonKeyPathsByPropertyKey];
        NSParameterAssert([keyPathsByPropertyKey isKindOfClass:NSDictionary.class]);
        [keyPathsByPropertyKey enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSParameterAssert([key isKindOfClass:NSString.class]);
            NSParameterAssert([obj isKindOfClass:NSString.class]);
        }];
        objc_setAssociatedObject(self, @selector(_keyPathsByPropertyKey), keyPathsByPropertyKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return keyPathsByPropertyKey;
}

+ (NSDictionary*)_propertyKeysByKeyPath{
    NSMutableDictionary * propertyKeysByKeyPath=objc_getAssociatedObject(self, @selector(_propertyKeysByKeyPath));
    if (!propertyKeysByKeyPath) {
        propertyKeysByKeyPath=[NSMutableDictionary dictionary];
        NSDictionary *  keyPathsByPropertyKey=[self _keyPathsByPropertyKey];
        [keyPathsByPropertyKey enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [propertyKeysByKeyPath setObject:key forKey:obj];
        }];
        objc_setAssociatedObject(self, @selector(_propertyKeysByKeyPath), propertyKeysByKeyPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return propertyKeysByKeyPath;
}

+ (NSValueTransformer*)_jsonValueTransformerForKey:(NSString*)key{
    if ([self.class respondsToSelector:@selector(jsonValueTransformerForKey:)]) {
        return [self.class jsonValueTransformerForKey:key];
    }
    return nil;
}

@end

@implementation OOModel (OODatabaseSerializing)

#pragma mark --
#pragma mark -- interface

+ (NSArray*)modelsWithSql:(NSString*)sql arguments:(NSArray*)arguments{
    NSParameterAssert(OOModelDatabase);
    [self _createTableIfNeed];
    NSString *table=[self _databaseTableName];
    NSArray * databaseDictionaries = [OOModelDatabase executeQuery:OOSelectSql(table, sql) arguments:arguments];
    NSMutableArray *models=[NSMutableArray array];
    for (NSDictionary * databaseDictionary in databaseDictionaries) {
        @autoreleasepool {
            id model=[self modelWithDictionary:[self _dictionaryWithDatabaseDictionary:databaseDictionary]];
            if (model) {
                [models addObject:model];
            }
        }
    }
    return models;
}

+ (instancetype)modelWithSql:(NSString*)sql arguments:(NSArray*)arguments{
    return [[self modelsWithSql:sql arguments:arguments] lastObject];
}

+ (void)deleteModelsWithSql:(NSString*)sql arguments:(NSArray*)arguments{
    NSParameterAssert(OOModelDatabase);
    NSString *table=[self _databaseTableName];
    [OOModelDatabase executeUpdate:OODeleteSql(table, sql) arguments:arguments];
}

+ (void)updateModels:(NSArray*)models{
    NSParameterAssert(OOModelDatabase);
    if ((!models)||(![models isKindOfClass:NSArray.class])) {
        OOModelLog(@"%@ is not a array!",models);
        return;
    }
    [self _createTableIfNeed];
    NSString *primaryKey=[self _databasePrimaryKey];
    if (primaryKey) {
        [self _updateModels:models];
    }else{
        [self _insertModels:models];
    }
}

- (void)update{
    [self.class updateModels:@[self]];
}

+ (BOOL)openDatabaseWithFile:(NSString *)file{
    OOModelDatabase=[OODatabase databaseWithFile:file];
    BOOL result = [OOModelDatabase open];
    if (result) {
        OOModelDatabaseOpenTime=-1;
    }else{
        OOModelDatabaseOpenTime=[[NSDate date]timeIntervalSince1970];
    }
    return result;
}

#pragma mark --
#pragma mark --

+ (void)_insertModels:(NSArray*)models{
    for(OOModel * model in models) {
        [self _insertModel:model];
    }
}

+ (void)_insertModel:(OOModel*)model{
    if (![model isKindOfClass:OOModel.class]) {
        OOModelLog(@"%@ is not subclass of OOModel!",model.class);
        return;
    }
    NSString *comma=@",";
    NSString *table=[self _databaseTableName];
    NSMutableString *sql1=[NSMutableString string];
    NSMutableString *sql2=[NSMutableString string];
    NSMutableArray *args=[NSMutableArray array];
    [sql1 appendFormat:@"insert into %@ (",table];
    [sql2 appendString:@" values ("];
    [[model databaseDictionary] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        @autoreleasepool {
            if (![obj isKindOfClass:NSNull.class]) {
                [sql1 appendFormat:@"%@%@",key,comma];
                [sql2 appendFormat:@"?%@",comma];
                [args addObject:obj];
            }
        }
    }];
    [sql1 deleteCharactersInRange:NSMakeRange(sql1.length-comma.length, comma.length)];
    [sql2 deleteCharactersInRange:NSMakeRange(sql2.length-comma.length,comma.length)];
    [sql1 appendString:@")"];
    [sql2 appendString:@")"];
    NSString *sql=[NSString stringWithFormat:@"%@%@",sql1,sql2];
    if ([sql rangeOfString:@"()"].location==NSNotFound) {
        [OOModelDatabase executeUpdate:sql arguments:args];
    }
}

+ (void)_updateModels:(NSArray*)models{
    for(OOModel * model in models) {
        [self _updateModel:model];
    }
}

+ (void)_updateModel:(OOModel*)model{
    if (![model isKindOfClass:OOModel.class]) {
        OOModelLog(@"%@ is not subclass of OOModel!",model.class);
        return;
    }
    NSString *primaryKey=[self _databasePrimaryKey];
    id primaryValue=[model _databasePrimaryValue];
    if ((!primaryValue)||[primaryValue isKindOfClass:NSNull.class]) {
        OOModelLog(@"%@'s primary value is not exist!",model);
        return;
    }
    NSString *databasePrimaryKey=[self databaseColumnForPropertyKey:primaryKey];
    NSString *sql=nil;
    sql=[NSString stringWithFormat:@"%@ = ?",databasePrimaryKey];
    id existModel=[self modelWithSql:sql arguments:@[primaryValue]];
    if (existModel) {
        [self _updateExistModel:model];
    }else{
        [self _insertModel:model];
    }
}

+ (void)_updateExistModel:(OOModel*)model{
    NSString *table=[self _databaseTableName];
    NSMutableString *sql=nil;
    NSMutableArray *args=[NSMutableArray array];
    NSString *and=@",";
    NSString *preSql=[NSString stringWithFormat:@"update %@ set ",table];
    sql=[preSql mutableCopy];
    NSString *primaryKey=[self _databasePrimaryKey];
    NSDictionary *databaseDictionary=[model databaseDictionary];
    [[databaseDictionary oo_dictionaryByRemoveKeys:@[primaryKey]] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        @autoreleasepool {
            if (![obj isKindOfClass:NSNull.class]) {
                [args addObject:obj];
                [sql appendFormat:@"%@=?%@",key,and];
            }
        }
    }];
    [sql deleteCharactersInRange:NSMakeRange(sql.length-and.length, and.length)];
    if ([sql length]<=preSql.length) {
        return;
    }
    NSString *databasePrimaryKey=[self databaseColumnForPropertyKey:primaryKey];
    id databasePrimaryValue=[databaseDictionary objectForKey:databasePrimaryKey];
    if (databasePrimaryValue&&![databasePrimaryValue isKindOfClass:NSNull.class]) {
        NSString *whereSql=[NSString stringWithFormat:@" where %@=?",databasePrimaryKey];
        [sql appendString:whereSql];
        [args addObject:databasePrimaryValue];
        if (sql.length>preSql.length+whereSql.length) {
            [OOModelDatabase executeUpdate:sql arguments:args];
        }
    }
}

#pragma mark --
#pragma mark -- validate once

+ (void)_validateOnce{
    NSParameterAssert([[self _columnsByPropertyKey] isKindOfClass:NSDictionary.class]);
    NSParameterAssert([[self _columnTypesByPropertyKey] isKindOfClass:NSDictionary.class]);
    NSParameterAssert([[self _databaseTableName] isKindOfClass:NSString.class]);
    [[self _columnsByPropertyKey] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSParameterAssert([key isKindOfClass:NSString.class]);
        NSParameterAssert([obj isKindOfClass:NSString.class]);
    }];
    [[self _columnTypesByPropertyKey] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSParameterAssert([key isKindOfClass:NSString.class]);
        NSParameterAssert([obj isKindOfClass:NSNumber.class]);
        NSParameterAssert([obj integerValue]>=0&&[obj integerValue]<OODatabaseColumnTypeBlob);
    }];
}

#pragma mark --
#pragma mark -- create

+ (void)_createTableIfNeed{
    if ([self _tableLastCreateTime]==OOModelDatabaseOpenTime) {
        return;
    }
    [self _createTable];
}

+ (void)_createTable{
    [self _validateOnce];
    NSString *table=[self _databaseTableName];
    if (![self _checkTable:table]) {
        NSString *primaryKey=[self _databasePrimaryKey];
        NSString *sql=nil;
        if (primaryKey) {
            NSString *databasePrimaryKey=[self databaseColumnForPropertyKey:primaryKey];
            NSNumber *typeNumber=[self _columnTypesByPropertyKey][primaryKey];
            NSParameterAssert(typeNumber);
            OODatabaseColumnType type=typeNumber.integerValue;
            NSString * primaryType=_columnTypeWithType(type);
            sql=[NSString stringWithFormat:@"create table if not exists '%@' ('id' integer not null primary key autoincrement,'%@' %@ not null unique)",table,databasePrimaryKey,primaryType];
        }else{
            sql=[NSString stringWithFormat:@"create table if not exists '%@' ('id' integer not null primary key autoincrement)",table];
        }
        [OOModelDatabase executeUpdate:sql arguments:nil];
    }
    [self _addColumns];
    [self _addIndexes];
}

+ (void)_addColumns{
    NSString *table = [self _databaseTableName];
    NSDictionary *columnsByPropertyKey=[self _columnsByPropertyKey];
    [columnsByPropertyKey enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *  _Nonnull column, BOOL * _Nonnull stop) {
        if (![self _checkTable:table column:column]) {
            OODatabaseColumnType type=[[self _columnTypesByPropertyKey][key] integerValue];
            NSString *columnType=_columnTypeWithType(type);
            NSString *sql=[NSString stringWithFormat:@"alter table '%@' add column '%@' %@",table,column,columnType];
            [OOModelDatabase executeUpdate:sql arguments:nil];
        }
    }];
}

+ (void)_addIndexes{
    NSArray *indexes=[self _databaseIndexesKeys];
    NSParameterAssert([indexes isKindOfClass:NSArray.class]||!indexes);
    NSString *table=[self _databaseTableName];
    NSMutableArray *databaseIndexes=[NSMutableArray array];
    [indexes enumerateObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSUInteger idx, BOOL * _Nonnull stop) {
        NSParameterAssert([propertyKey isKindOfClass:NSString.class]);
        NSString *databaseColumn=[self databaseColumnForPropertyKey:propertyKey];
        NSParameterAssert([databaseColumn isKindOfClass:NSString.class]);
        [databaseIndexes addObject:databaseColumn];
    }];
    [databaseIndexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self _chekTable:table index:obj]) {
            NSString *index=[NSString stringWithFormat:@"%@_%@_index",table,obj];
            NSString *sql=[NSString stringWithFormat:@"create index %@ on %@(%@)",index,table,obj];
            [OOModelDatabase executeUpdate:sql arguments:nil];
        }
    }];
    [self _setTableLastCreateTime:OOModelDatabaseOpenTime];
}

#pragma mark --
#pragma mark -- check func

+ (BOOL)_checkTable:(NSString*)table{
    NSString * sql=@"select * from sqlite_master where tbl_name=? and type='table'";
    NSArray * sets=[OOModelDatabase executeQuery:sql arguments:@[table]];
    if (sets.count>0) {
        return YES;
    }else{
        return NO;
    }
}

+ (BOOL)_checkTable:(NSString*)table column:(NSString*)column{
    BOOL ret=NO;
    NSString * sql=@"select sql from sqlite_master where tbl_name=? and type='table'";
    NSArray * sets=[OOModelDatabase executeQuery:sql arguments:@[table]];
    if (sets.count>0) {
        for(NSDictionary * set in sets) {
            NSString *createSql=set[@"sql"];
            if (createSql&&[createSql rangeOfString:column].location!=NSNotFound) {
                ret=YES;
                break;
            }
        }
    }
    return ret;
}

+ (BOOL)_chekTable:(NSString*)table index:(NSString*)index{
    __block BOOL ret;
    NSString * sql=@"select * from sqlite_master where tbl_name=? and type='index'";
    ret=NO;
    NSArray * sets=[OOModelDatabase executeQuery:sql arguments:@[table]];
    if (sets.count>0) {
        for(NSDictionary * set in sets) {
            NSString *createSql=set[@"sql"];
            if (createSql&&[createSql rangeOfString:index].location!=NSNotFound) {
                ret=YES;
                break;
            }
        }
    }
    return ret;
}

+ (BOOL)_checkTable:(NSString*)table primaryKey:(NSString*)key primaryValue:(id)value {
    NSParameterAssert(value);
    NSString *sql=[NSString stringWithFormat:@"select * from %@ where %@=?",table,key];
    NSArray * sets=[OOModelDatabase executeQuery:sql arguments:@[value]];
    if (sets.count>0) {
        return YES;
    }else{
        return NO;
    }
}

#pragma mark --
#pragma mark -- setter

+ (void)_setTableLastCreateTime:(NSTimeInterval)time{
    objc_setAssociatedObject(self, @selector(_tableLastCreateTime), @(time), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark --
#pragma mark -- getter

+ (NSString*)propertyKeyForDatabaseColumn:(NSString*)column{
    return [self _propertyKeysByColumn][column];
}

+ (NSString*)databaseColumnForPropertyKey:(NSString*)propertyKey{
    return [self _columnsByPropertyKey][propertyKey];
}

+ (id)valueWithDatabaseValue:(id)value forPropertyKey:(NSString *)propertyKey{
    NSValueTransformer *valueTransformer=[self _databaseValueTransformerForKey:propertyKey];
    if (valueTransformer) {
        return [valueTransformer transformedValue:value];
    }
    return value;
}

+ (id)databaseValueWithValue:(id)value forPropertyKey:(NSString*)propertyKey{
    NSValueTransformer *valueTransformer=[self _databaseValueTransformerForKey:propertyKey];
    if (valueTransformer) {
        return [valueTransformer reverseTransformedValue:value];
    }
    return value;
}

- (NSDictionary*)databaseDictionary{
    NSDictionary *dictionary=[self dictionary];
    return [self.class _databaseDictionaryWithDictionary:dictionary];
}

+ (NSDictionary*)_databaseDictionaryWithDictionary:(NSDictionary*)dictionary{
    NSMutableDictionary *databaseDictionary=[NSMutableDictionary dictionary];
    if ([dictionary isKindOfClass:NSDictionary.class]) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, id  _Nonnull value, BOOL * _Nonnull stop) {
            NSString *databaseColumn=[self databaseColumnForPropertyKey:propertyKey];
            id databaseValue=[self databaseValueWithValue:value forPropertyKey:propertyKey];
            if (databaseValue) {
                [databaseDictionary setObject:databaseValue forKey:databaseColumn];
            }
        }];
    }
    return databaseDictionary;
}

+ (NSDictionary*)_dictionaryWithDatabaseDictionary:(NSDictionary*)databaseDictionary{
    if (![databaseDictionary isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    [databaseDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull column, id  _Nonnull databaseValue, BOOL * _Nonnull stop) {
        @autoreleasepool {
            NSString * propertyKey=[self propertyKeyForDatabaseColumn:column];
            if (propertyKey&&![databaseValue isKindOfClass:NSNull.class]) {
               id value =[self valueWithDatabaseValue:databaseValue forPropertyKey:propertyKey];
                if (value) {
                    [dictionary setObject:value forKey:propertyKey];
                }
            }
        }
    }];
    return dictionary;
}

+ (NSDictionary*)_columnsByPropertyKey{
    NSDictionary * columnsByPropertyKey=objc_getAssociatedObject(self, @selector(_columnsByPropertyKey));
    if (!columnsByPropertyKey) {
        columnsByPropertyKey=[self.class databaseColumnsByPropertyKey];
        objc_setAssociatedObject(self, @selector(_columnsByPropertyKey), columnsByPropertyKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return columnsByPropertyKey;
}

+ (NSDictionary*)_propertyKeysByColumn{
    NSMutableDictionary * propertyKeysByColumn=objc_getAssociatedObject(self, @selector(_propertyKeysByColumn));
    if (!propertyKeysByColumn) {
        propertyKeysByColumn=[NSMutableDictionary dictionary];
        NSDictionary * columnsByPropertyKey=[self _columnsByPropertyKey];
        [columnsByPropertyKey enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [propertyKeysByColumn setObject:key forKey:obj];
        }];
        objc_setAssociatedObject(self, @selector(_propertyKeysByColumn), propertyKeysByColumn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return propertyKeysByColumn;
}

+ (NSDictionary*)_columnTypesByPropertyKey{
    NSDictionary * columnTypesByPropertyKey=objc_getAssociatedObject(self, @selector(_columnTypesByPropertyKey));
    if (!columnTypesByPropertyKey) {
        columnTypesByPropertyKey=[self.class databaseColumnTypesByPropertyKey];
        objc_setAssociatedObject(self, @selector(_columnTypesByPropertyKey), columnTypesByPropertyKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return columnTypesByPropertyKey;
}

+ (NSString*)_databaseTableName{
    NSString * databaseTableName=objc_getAssociatedObject(self, @selector(_databaseTableName));
    if (!databaseTableName) {
        databaseTableName=[self.class databaseTableName];
        objc_setAssociatedObject(self, @selector(_databaseTableName),databaseTableName, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return databaseTableName;
}

+ (NSString*)_databasePrimaryKey{
    NSString * databasePrimaryKey=objc_getAssociatedObject(self, @selector(_databasePrimaryKey));
    if (!databasePrimaryKey) {
        if (![self.class respondsToSelector:@selector(databasePrimaryKey)]) {
            return nil;
        }
        databasePrimaryKey=[self.class databasePrimaryKey];
        if (databasePrimaryKey) {
            NSParameterAssert([databasePrimaryKey isKindOfClass:NSString.class]);
        }
        objc_setAssociatedObject(self, @selector(_databasePrimaryKey),databasePrimaryKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return databasePrimaryKey;
}

- (id<NSCopying>)_databasePrimaryValue{
    return [self valueForKey:[self.class _databasePrimaryKey]];
}

+ (NSArray*)_databaseIndexesKeys{
    if ([self.class respondsToSelector:@selector(databaseIndexesKeys)]) {
        return [self.class databaseIndexesKeys];
    }
    return nil;
}

+ (NSValueTransformer*)_databaseValueTransformerForKey:(NSString*)key{
    if ([self.class respondsToSelector:@selector(databaseValueTransformerForKey:)]) {
        return [self.class databaseValueTransformerForKey:key];
    }
    return nil;
}

+ (NSTimeInterval)_tableLastCreateTime{
    return [objc_getAssociatedObject(self, @selector(_tableLastCreateTime)) doubleValue];
}

@end

@implementation OOModel (OOManagerSerializing)

#pragma mark --
#pragma mark -- init

+ (NSArray*)oo_modelsWithDictionaries:(NSArray*)dictionaries{
    NSMutableArray *models=[NSMutableArray array];
    for (NSDictionary * dictionary in dictionaries){
        id model=[self.class oo_modelWithDictionary:dictionary];
        if (model) {
            [models addObject:model];
        }
    }
    return models;
}

+ (instancetype)oo_modelWithDictionary:(NSDictionary*)dictionary{
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        OOModelLog(@"%@ is not a dictionary!",dictionary);
        return nil;
    }
    NSString *managerPrimaryKey=[self _managerPrimaryKey];
    OOModel * newModel=[self modelWithDictionary:dictionary];
    NSObject * managerPrimaryValue=(NSObject*)[newModel valueForKey:managerPrimaryKey];
    if ((!managerPrimaryValue)||[managerPrimaryValue isKindOfClass:NSNull.class]) {
        OOModelLog(@"primaryValue is nil!");
        return nil;
    }
    OOModel * oldModel=[self _modelInMapTableWithManagerPrimaryValue:(id)managerPrimaryValue];
    if (oldModel) {
        [oldModel mergeWithDictionary:dictionary];
        [oldModel update];
        OOModelLog(@"from mapTable:%@,%@:%@",NSStringFromClass(self.class),managerPrimaryKey,managerPrimaryValue);
        return oldModel;
    }else{
        if (newModel) {
            [newModel update];
            NSString *primaryKey=[self _databasePrimaryKey];
            id primaryValue=[newModel valueForKey:primaryKey];
            id databasePrimaryValue=[self.class databaseValueWithValue:primaryValue forPropertyKey:primaryKey];
            if ((!databasePrimaryValue)||[databasePrimaryValue isKindOfClass:NSNull.class]) {
                OOModelLog(@"primaryValue is nil!");
                return nil;
            }
            NSString *databasePrimaryKey=[self _columnsByPropertyKey][primaryKey];
            newModel=[self modelWithSql:[NSString stringWithFormat:@"%@=?",databasePrimaryKey] arguments:@[databasePrimaryValue]];
            if (newModel) {
                [[self _mapTable] setObject:newModel forKey:primaryValue];
                OOModelLog(@"from database:%@,%@:%@",NSStringFromClass(self.class),primaryKey,managerPrimaryValue);
                return newModel;
            }
        }
    }
    OOModelLog(@"model is not exist in database!");
    return nil;
}

- (BOOL)oo_mergeWithDictionary:(NSDictionary*)dictionary{
    BOOL result = [self mergeWithDictionary:dictionary];
    if (result) {
        [self update];
    }
    return result;
}

+ (NSArray*)oo_modelsWithJsonDictionaries:(NSArray *)jsonDictionaries{
    NSMutableArray *models=[NSMutableArray array];
    for (NSDictionary * jsonDictionary in jsonDictionaries){
        id model=[self.class oo_modelWithJsonDictionary:jsonDictionary];
        if (model) {
            [models addObject:model];
        }
    }
    return models;
}

+ (instancetype)oo_modelWithJsonDictionary:(NSDictionary*)jsonDictionary{
    return [self oo_modelWithDictionary:[self _dictionaryWithJsonDictionary:jsonDictionary]];
}

- (BOOL)oo_mergeWithJsonDictionary:(NSDictionary*)jsonDictionary{
    return [self oo_mergeWithDictionary:[self.class _dictionaryWithJsonDictionary:jsonDictionary]];
}

+ (NSArray*)oo_modelsWithSql:(NSString*)sql arguments:(NSArray*)arguments{
    NSArray * selectedModels=[self modelsWithSql:sql arguments:arguments];
    NSMutableArray *dbModels=[NSMutableArray array];
    for (OOModel * dbModel in selectedModels){
        NSString * managerPrimaryKey=[dbModel.class _managerPrimaryKey];
        NSObject  *managerPrimaryValue=[dbModel valueForKey:managerPrimaryKey];
        OOModel * managedModel=[[self _mapTable] objectForKey:managerPrimaryValue];
        if (managedModel) {
            [dbModels addObject:managedModel];
        }else{
            [dbModels addObject:dbModel];
        }
    }
    return dbModels;
}

+ (instancetype)oo_modelWithSql:(NSString*)sql arguments:(NSArray*)arguments{
    return [[self oo_modelsWithSql:sql arguments:arguments] lastObject];
}

#pragma mark --
#pragma mark -- getter

+ (NSString *)_managerPrimaryKey{
    NSString *managerPrimaryKey=objc_getAssociatedObject(self, @selector(_managerPrimaryKey));
    if (!managerPrimaryKey) {
        managerPrimaryKey=[self.class managerPrimaryKey];
        objc_setAssociatedObject(self, @selector(_managerPrimaryKey), managerPrimaryKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return managerPrimaryKey;
}

+ (NSString*)_mapTableName{
    NSString *mapTable=objc_getAssociatedObject(self, @selector(_mapTableName));
    if (!mapTable) {
        mapTable=[self.class managerMapTableName];
        NSParameterAssert([mapTable isKindOfClass:NSString.class]);
        objc_setAssociatedObject(self, @selector(_mapTableName), mapTable, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return mapTable;
}

+ (NSMapTable*)_mapTable{
    void * key=(__bridge void *)[self _mapTableName];
    NSMapTable * mapTable=objc_getAssociatedObject(self,key);
    if (!mapTable) {
        mapTable=[NSMapTable strongToWeakObjectsMapTable];
        objc_setAssociatedObject(self,key, mapTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return mapTable;
}

+ (OOModel*)_modelInMapTableWithManagerPrimaryValue:(id<NSCopying>)primaryValue{
    return [[self _mapTable] objectForKey:primaryValue];
}




@end