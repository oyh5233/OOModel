//
//  OOModel.m
//  OOModel
//

#import "OOModel.h"
#import "OODatabase.h"
#import "objc/runtime.h"

static OODatabase *OOModelDatabase=nil;
static NSTimeInterval OOModelDatabaseOpenTime=-1;
static NSString * const OOModelCoderKey=@"OOModelCoderKey";
#define OOSelectSql(table,sql) [NSString stringWithFormat:@"select * from %@ where %@",table,sql]
#define OOSelect(table) [NSString stringWithFormat:@"select * from %@",table]

#define OODeleteSql(table,sql) [NSString stringWithFormat:@"delete from %@ where %@",table,sql]

#define OODelete(table) [NSString stringWithFormat:@"delete from %@",table]

inline static NSString* _databaseColumnTypeWithType(OODatabaseColumnType type) {
    NSString *databaseColumnType=nil;
    switch (type) {
        case OODatabaseColumnTypeText:
            databaseColumnType=@"text";
            break;
        case OODatabaseColumnTypeInteger:
            databaseColumnType=@"integer";
            break;
        case OODatabaseColumnTypeReal:
            databaseColumnType=@"real";
            break;
        case OODatabaseColumnTypeBlob:
            databaseColumnType=@"blob";
            break;
        default:
            assert(NO);
            break;
    }
    return databaseColumnType;
}

@implementation OOModel

#pragma mark --
#pragma mark -- init
+ (NSArray *)modelsWithDictionaries:(NSArray*)dictionaries{
    NSMutableArray *models=[NSMutableArray array];
    for (NSDictionary * dictionary in dictionaries){
        id model = [self modelWithDictionary:dictionary];
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
        OOModelLog(@"parameter is not a NSDictionary!");
        return NO;
    }
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:NSNull.class]) {
            id validateObj=obj;
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
   return [self mergeWithDictionary:[model dictionary]];
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
    NSMutableArray *cachedPropertyKeys = objc_getAssociatedObject(self, @selector(propertyKeys));
    if (!cachedPropertyKeys) {
        cachedPropertyKeys = [NSMutableArray array];
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
                    [cachedPropertyKeys addObject:key];
                }
            }
        }];
        objc_setAssociatedObject(self, @selector(propertyKeys), cachedPropertyKeys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cachedPropertyKeys;
}

- (NSDictionary*)dictionary{
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    [[self.class propertyKeys] enumerateObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSUInteger idx, BOOL * _Nonnull stop) {
        id value=[self valueForKey:propertyKey];
        if (![value isKindOfClass:NSNull.class]) {
            [dictionary setObject:value forKey:propertyKey];
        }
    }];
    return dictionary;
}

#pragma mark --
#pragma mark -- coding
- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:[self dictionary] forKey:OOModelCoderKey];
}
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder{
    NSDictionary *dictionary=[aDecoder decodeObjectForKey:OOModelCoderKey];
    Protocol *protocol= objc_getProtocol("OODatabaseSerializing");
    if (class_conformsToProtocol(self.class, protocol)) {
        return [self.class oo_modelWithDictionary:dictionary];
    }else{
        return [self.class modelWithDictionary:dictionary];
    }
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
        id model = [self modelWithJsonDictionary:jsonDictionary];
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

- (NSDictionary*)jsonDictionary{
    return [self.class _jsonDictionaryWithDictionary:[self dictionary]];
}

+ (NSString*)propertyKeyForJsonKeyPath:(NSString*)keyPath{
    return [self _jsonPropertyKeysByKeyPaths][keyPath];
}

+ (NSString*)jsonKeyPathForPropertyKey:(NSString*)propertyKey{
    return [self _jsonKeyPathsByPropertyKeys][propertyKey];
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

+ (NSDictionary*)_dictionaryWithJsonDictionary:(NSDictionary*)jsonDictionary{
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    [[self _jsonKeyPathsByPropertyKeys] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSString *  _Nonnull keyPath, BOOL * _Nonnull stop) {
        id jsonValue=[jsonDictionary valueForKeyPath:keyPath];
        if (jsonValue) {
            id value=[self valueWithJsonValue:jsonValue forPropertyKey:propertyKey];
            if (value) {
                [dictionary setObject:value forKey:propertyKey];
            }
        }
    }];
    return dictionary;
}

+ (NSDictionary*)_jsonDictionaryWithDictionary:(NSDictionary*)dictionary{
    NSMutableDictionary *jsonDictionary=[NSMutableDictionary dictionary];
    [[self _jsonKeyPathsByPropertyKeys] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSString *  _Nonnull keyPath, BOOL * _Nonnull stop) {
        [self _autoCompleteJsonDictionary:jsonDictionary ForKeyPath:keyPath];
    }];
    if ([dictionary isKindOfClass:NSDictionary.class]) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, id  _Nonnull value, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString *keyPath=[self _jsonKeyPathsByPropertyKeys][propertyKey];
                if (keyPath) {
                    id jsonValue=[self jsonValueWithValue:value forPropertyKey:propertyKey];
                    if (jsonValue) {
                        [jsonDictionary setValue:jsonValue forKeyPath:keyPath];
                    }
                }
            }
        }];
    }
    return jsonDictionary;
}

+ (void)_autoCompleteJsonDictionary:(NSMutableDictionary*)jsonDictionary ForKeyPath:(NSString*)keyPath{
    NSArray * comps=[keyPath componentsSeparatedByString:@"."];
    NSMutableDictionary *childDictionary=nil;
    NSMutableDictionary *parentDictionary=jsonDictionary;
    for (int i = 0 ; i < comps.count ; i++){
        if (i>0) {
            NSString *parentPath=comps[i-1];
            childDictionary=[NSMutableDictionary dictionary];
            [parentDictionary setObject:childDictionary forKey:parentPath];
            parentDictionary=childDictionary;
        }
    }

}

+ (NSDictionary*)_jsonKeyPathsByPropertyKeys{
    NSDictionary * jsonKeyPathsByPropertyKeys=objc_getAssociatedObject(self, @selector(_jsonKeyPathsByPropertyKeys));
    if (!jsonKeyPathsByPropertyKeys) {
        jsonKeyPathsByPropertyKeys=[self.class jsonKeyPathsByPropertyKeys];
        NSParameterAssert([jsonKeyPathsByPropertyKeys isKindOfClass:NSDictionary.class]);
        [jsonKeyPathsByPropertyKeys enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSParameterAssert([key isKindOfClass:NSString.class]);
            NSParameterAssert([obj isKindOfClass:NSString.class]);
        }];
        objc_setAssociatedObject(self, @selector(_jsonKeyPathsByPropertyKeys), jsonKeyPathsByPropertyKeys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return jsonKeyPathsByPropertyKeys;
}

+ (NSDictionary*)_jsonPropertyKeysByKeyPaths{
    NSMutableDictionary * jsonPropertyKeysByKeyPaths=objc_getAssociatedObject(self, @selector(_jsonPropertyKeysByKeyPaths));
    if (!jsonPropertyKeysByKeyPaths) {
        jsonPropertyKeysByKeyPaths=[NSMutableDictionary dictionary];
        NSDictionary *  keyPathsByPropertyKey=[self _jsonKeyPathsByPropertyKeys];
        [keyPathsByPropertyKey enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [jsonPropertyKeysByKeyPaths setObject:key forKey:obj];
        }];
        objc_setAssociatedObject(self, @selector(_jsonPropertyKeysByKeyPaths), jsonPropertyKeysByKeyPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return jsonPropertyKeysByKeyPaths;
}

+ (NSValueTransformer*)_jsonValueTransformerForKey:(NSString*)key{
    if ([self respondsToSelector:@selector(jsonValueTransformerForKey:)]) {
        return [self.class jsonValueTransformerForKey:key];
    }
    return nil;
}

@end

@implementation OOModel (OODatabaseSerializing)

#pragma mark --
#pragma mark -- database open close

+ (BOOL)openDatabaseWithFile:(NSString *)file{
    if (![self closeDatabase]) {
        return NO;
    }
    OOModelDatabase=[OODatabase databaseWithFile:file];
    BOOL result = [OOModelDatabase open];
    if (result) {
        OOModelDatabaseOpenTime=[[NSDate date]timeIntervalSince1970];
    }else{
        OOModelDatabaseOpenTime=-1;
        OOModelLog(@"open database fail:%@",file);
    }
    return result;
}

+ (BOOL)closeDatabase{
    BOOL result = YES;
    if (OOModelDatabase) {
        result = [OOModelDatabase close];
        if (result) {
            OOModelDatabase=nil;
        }else{
            OOModelLog(@"database close fail!");
        }
    }
    return result;
}

#pragma mark --
#pragma mark -- interface

+ (NSArray*)modelsWithSql:(NSString*)sql arguments:(NSArray*)arguments{
    NSParameterAssert(OOModelDatabase);
    [self _createTableIfNeed];
    NSString *table=[self _databaseTableName];
    NSArray * databaseDictionaries = nil;
    if (sql) {
        databaseDictionaries=[OOModelDatabase executeQuery:OOSelectSql(table, sql) arguments:arguments];
    }else{
       databaseDictionaries= [OOModelDatabase executeQuery:OOSelect(table) arguments:arguments];
    }
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
    if (sql.length>0) {
        [OOModelDatabase executeUpdate:OODeleteSql(table, sql) arguments:arguments];
    }else{
        [OOModelDatabase executeUpdate:OODelete(table) arguments:arguments];
    }
}

+ (void)updateModels:(NSArray*)models{
    NSParameterAssert(OOModelDatabase);
    if ((!models)||(![models isKindOfClass:NSArray.class])) {
        OOModelLog(@"parameter is not a array!");
        return;
    }
    for (OOModel * model in models){
        [model update];
    }
}

- (void)update{
    NSParameterAssert(OOModelDatabase);
    [self.class _createTableIfNeed];
    NSString *databasePrimaryKey=[self.class _databasePrimaryKey];
    if (databasePrimaryKey) {
        [self.class _updateModel:self];
    }else{
        [self.class _insertModel:self];
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
    NSParameterAssert([[self _databaseColumnsByPropertyKeys] isKindOfClass:NSDictionary.class]);
    NSParameterAssert([[self _databaseColumnTypesByPropertyKeys] isKindOfClass:NSDictionary.class]);
    NSParameterAssert([[self _databaseTableName] isKindOfClass:NSString.class]);
    [[self _databaseColumnsByPropertyKeys] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSParameterAssert([key isKindOfClass:NSString.class]);
        NSParameterAssert([obj isKindOfClass:NSString.class]);
    }];
    [[self _databaseColumnTypesByPropertyKeys] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
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
    [self _addColumns];
    [self _addIndexes];
}

+ (void)_createTable{
    [self _validateOnce];
    NSString *table=[self _databaseTableName];
    if (![self _checkTable:table]) {
        NSString *primaryKey=[self _databasePrimaryKey];
        NSString *sql=nil;
        if (primaryKey) {
            NSString *databasePrimaryKey=[self databaseColumnForPropertyKey:primaryKey];
            NSNumber *typeNumber=[self _databaseColumnTypesByPropertyKeys][primaryKey];
            NSParameterAssert(typeNumber);
            OODatabaseColumnType type=typeNumber.integerValue;
            NSString * primaryType=_databaseColumnTypeWithType(type);
            sql=[NSString stringWithFormat:@"create table if not exists '%@' ('id' integer not null primary key autoincrement,'%@' %@ not null unique)",table,databasePrimaryKey,primaryType];
        }else{
            sql=[NSString stringWithFormat:@"create table if not exists '%@' ('id' integer not null primary key autoincrement)",table];
        }
        [OOModelDatabase executeUpdate:sql arguments:nil];
    }
}

+ (void)_addColumns{
    NSString *table = [self _databaseTableName];
    NSDictionary *databaseColumnsByPropertyKeys=[self _databaseColumnsByPropertyKeys];
    [databaseColumnsByPropertyKeys enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSString *  _Nonnull column, BOOL * _Nonnull stop) {
        if (![self _checkTable:table column:column]) {
            OODatabaseColumnType type=[[self _databaseColumnTypesByPropertyKeys][propertyKey] integerValue];
            NSString *columnType=_databaseColumnTypeWithType(type);
            NSString *sql=[NSString stringWithFormat:@"alter table '%@' add column '%@' %@",table,column,columnType];
            [OOModelDatabase executeUpdate:sql arguments:nil];
        }
    }];
}

+ (void)_addIndexes{
    NSArray *indexesKeys=[self _databaseIndexesKeys];
    NSParameterAssert([indexesKeys isKindOfClass:NSArray.class]||!indexesKeys);
    NSString *table=[self _databaseTableName];
    NSMutableArray *databaseIndexesKeys=[NSMutableArray array];
    [indexesKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSUInteger idx, BOOL * _Nonnull stop) {
        NSParameterAssert([propertyKey isKindOfClass:NSString.class]);
        NSString *databaseColumn=[self databaseColumnForPropertyKey:propertyKey];
        NSParameterAssert([databaseColumn isKindOfClass:NSString.class]);
        [databaseIndexesKeys addObject:databaseColumn];
    }];
    [databaseIndexesKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull databaseIndexKey, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self _chekTable:table index:databaseIndexKey]) {
            NSString *index=[NSString stringWithFormat:@"%@_%@_index",table,databaseIndexKey];
            NSString *sql=[NSString stringWithFormat:@"create index %@ on %@(%@)",index,table,databaseIndexKey];
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
    return [self _databasePropertyKeysByColumns][column];
}

+ (NSString*)databaseColumnForPropertyKey:(NSString*)propertyKey{
    return [self _databaseColumnsByPropertyKeys][propertyKey];
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
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSMutableDictionary *databaseDictionary=[NSMutableDictionary dictionary];
    if ([dictionary isKindOfClass:NSDictionary.class]) {
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, id  _Nonnull value, BOOL * _Nonnull stop) {
            @autoreleasepool {
                NSString *databaseColumn=[self databaseColumnForPropertyKey:propertyKey];
                if (databaseColumn) {
                    id databaseValue=[self databaseValueWithValue:value forPropertyKey:propertyKey];
                    if (databaseValue) {
                        [databaseDictionary setObject:databaseValue forKey:databaseColumn];
                    }
                }
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
            if (propertyKey) {
               id value =[self valueWithDatabaseValue:databaseValue forPropertyKey:propertyKey];
                if (value) {
                    [dictionary setObject:value forKey:propertyKey];
                }
            }
        }
    }];
    return dictionary;
}

+ (NSDictionary*)_databaseColumnsByPropertyKeys{
    NSDictionary * databaseColumnsByPropertyKeys=objc_getAssociatedObject(self, @selector(_databaseColumnsByPropertyKeys));
    if (!databaseColumnsByPropertyKeys) {
        databaseColumnsByPropertyKeys=[self.class databaseColumnsByPropertyKeys];
        objc_setAssociatedObject(self, @selector(_databaseColumnsByPropertyKeys), databaseColumnsByPropertyKeys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return databaseColumnsByPropertyKeys;
}

+ (NSDictionary*)_databasePropertyKeysByColumns{
    NSMutableDictionary * databasePropertyKeysByColumns=objc_getAssociatedObject(self, @selector(_databasePropertyKeysByColumns));
    if (!databasePropertyKeysByColumns) {
        databasePropertyKeysByColumns=[NSMutableDictionary dictionary];
        NSDictionary * columnsByPropertyKey=[self _databaseColumnsByPropertyKeys];
        [columnsByPropertyKey enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [databasePropertyKeysByColumns setObject:key forKey:obj];
        }];
        objc_setAssociatedObject(self, @selector(_databasePropertyKeysByColumns), databasePropertyKeysByColumns, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return databasePropertyKeysByColumns;
}

+ (NSDictionary*)_databaseColumnTypesByPropertyKeys{
    NSDictionary * databaseColumnTypesByPropertyKey=objc_getAssociatedObject(self, @selector(_databaseColumnTypesByPropertyKeys));
    if (!databaseColumnTypesByPropertyKey) {
        databaseColumnTypesByPropertyKey=[self.class databaseColumnTypesByPropertyKeys];
        objc_setAssociatedObject(self, @selector(_databaseColumnTypesByPropertyKeys), databaseColumnTypesByPropertyKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return databaseColumnTypesByPropertyKey;
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
        if (![self respondsToSelector:@selector(databasePrimaryKey)]) {
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
    if ([self respondsToSelector:@selector(databaseIndexesKeys)]) {
        return [self.class databaseIndexesKeys];
    }
    return nil;
}

+ (NSValueTransformer*)_databaseValueTransformerForKey:(NSString*)key{
    if ([self respondsToSelector:@selector(databaseValueTransformerForKey:)]) {
        return [self.class databaseValueTransformerForKey:key];
    }
    return nil;
}

+ (NSTimeInterval)_tableLastCreateTime{
    return [objc_getAssociatedObject(self, @selector(_tableLastCreateTime)) doubleValue];
}

@end

@implementation OOModel (OOManagedObject)

#pragma mark --
#pragma mark -- init

+ (NSArray*)oo_modelsWithDictionaries:(NSArray*)dictionaries{
    NSMutableArray *models=[NSMutableArray array];
    for (NSDictionary * dictionary in dictionaries){
        id model=[self oo_modelWithDictionary:dictionary];
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
    OOModel * oldModel=[self _modelInManagedMapTableWithManagedPrimaryValue:(id)managerPrimaryValue];
    if (oldModel) {
        [oldModel mergeWithDictionary:dictionary];
        [oldModel update];
        return oldModel;
    }else{
        if (newModel) {
            NSString *primaryKey=[self _databasePrimaryKey];
            id primaryValue=[newModel valueForKey:primaryKey];
            id databasePrimaryValue=[self databaseValueWithValue:primaryValue forPropertyKey:primaryKey];
            if ((!databasePrimaryValue)||[databasePrimaryValue isKindOfClass:NSNull.class]) {
                return nil;
            }
            NSString *databasePrimaryKey=[self _databaseColumnsByPropertyKeys][primaryKey];
            OOModel *databaseModel=[self modelWithSql:[NSString stringWithFormat:@"%@=?",databasePrimaryKey] arguments:@[databasePrimaryValue]];
            if (databaseModel) {
                [databaseModel mergeWithModel:newModel];
                newModel=databaseModel;
            }
            [newModel update];
            return newModel;
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
        id model=[self oo_modelWithJsonDictionary:jsonDictionary];
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

+ (void)oo_updateModels:(NSArray*)models{
    for (OOModel * model in models){
        NSString * managerPrimaryKey=[model.class _managerPrimaryKey];
        NSObject  *managerPrimaryValue=[model valueForKey:managerPrimaryKey];
        if (managerPrimaryValue) {
            OOModel * managedModel=[[self _mapTable] objectForKey:managerPrimaryValue];
            if (managedModel) {
                [managedModel mergeWithModel:model];
                [managedModel update];
            }else{
                [model update];
            }
        }else{
            OOModelLog(@"%@ dont have a managerPrimaryValue!",model);
        }
    }
}

- (void)oo_update{
    [self.class oo_updateModels:@[self]];
}

- (void)oo_mergeWithModel:(OOModel*)model{
    
}
#pragma mark --
#pragma mark -- getter

+ (NSString *)_managerPrimaryKey{
    NSString *managerPrimaryKey=objc_getAssociatedObject(self, @selector(_managerPrimaryKey));
    if (!managerPrimaryKey) {
        managerPrimaryKey=[self.class managedPrimaryKey];
        objc_setAssociatedObject(self, @selector(_managerPrimaryKey), managerPrimaryKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return managerPrimaryKey;
}

+ (NSString*)_managedMapTableName{
    NSString *managedMapTable=objc_getAssociatedObject(self, @selector(_managedMapTableName));
    if (!managedMapTable) {
        managedMapTable=[self.class managedMapTableName];
        NSParameterAssert([managedMapTable isKindOfClass:NSString.class]);
        objc_setAssociatedObject(self, @selector(_managedMapTableName), managedMapTable, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return managedMapTable;
}

+ (NSMapTable*)_mapTable{
    void * key=(__bridge void *)[self _managedMapTableName];
    NSMapTable * mapTable=objc_getAssociatedObject(self,key);
    if (!mapTable) {
        mapTable=[NSMapTable strongToWeakObjectsMapTable];
        objc_setAssociatedObject(self,key, mapTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return mapTable;
}

+ (OOModel*)_modelInManagedMapTableWithManagedPrimaryValue:(id<NSCopying>)primaryValue{
    return [[self _mapTable] objectForKey:primaryValue];
}




@end