//
//  OOModel+OODatabaseSerializing.m
//  OOModel
//

#import "OOModel+OODatabaseSerializing.h"
#import "OODatabase.h"
#import "objc/runtime.h"

static OODatabase *modelDatabase=nil;
static NSTimeInterval modelDatabaseOpenTime=-1;

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
@implementation OOModel (OODatabaseSerializing)

#pragma mark --
#pragma mark -- interface

+ (NSArray*)modelsWithSql:(NSString*)sql arguments:(NSArray*)arguments{
    NSParameterAssert(modelDatabase);
    [self _createTableIfNeed];
    NSString *table=[self.class _table];
   NSArray * databaseDictionaries = [modelDatabase executeQuery:OOSelectSql(table, sql) arguments:arguments];
    NSMutableArray *models=[NSMutableArray array];
    for (NSDictionary * databaseDictionary in databaseDictionaries) {
        @autoreleasepool {
            id model=[self modelWithDictionary:[self.class _dictionaryWithDatabaseDictionary:databaseDictionary]];
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
    NSParameterAssert(modelDatabase);
    NSString *table=[self.class _table];
    [modelDatabase executeUpdate:OODeleteSql(table, sql) arguments:arguments];
}

+ (void)updateModels:(NSArray*)models{
    NSParameterAssert(modelDatabase);
    if ((!models)||(![models isKindOfClass:NSArray.class])) {
        OOModelLog(@"%@ is not a array!",models);
        return;
    }
    [self _createTableIfNeed];
    NSString *primaryKey=[self _primaryKey];
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
    modelDatabase=[OODatabase databaseWithFile:file];
    BOOL result = [modelDatabase open];
    if (result) {
        modelDatabaseOpenTime=-1;
    }else{
        modelDatabaseOpenTime=[[NSDate date]timeIntervalSince1970];
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
    NSString *table=[self _table];
    NSMutableString *sql1=[NSMutableString string];
    NSMutableString *sql2=[NSMutableString string];
    NSMutableArray *args=[NSMutableArray array];
    [sql1 appendFormat:@"insert into %@ (",table];
    [sql2 appendString:@" values ("];
    [[model.class _columnsByPropertyKey] enumerateKeysAndObjectsUsingBlock:^(NSString * propertyKey, NSString *databaseColumn, BOOL *stop) {
        @autoreleasepool {
            id value = [[model dictionary] objectForKey:propertyKey];
            if (value&&![value isKindOfClass:NSNull.class]) {
                NSValueTransformer *valueTransformer=[model.class _databaseValueTransformerForKey:propertyKey];
                if (valueTransformer) {
                    value=[valueTransformer transformedValue:value];
                }
                if (value&&![value isKindOfClass:NSNull.class]) {
                    [sql1 appendFormat:@"%@%@",databaseColumn,comma];
                    [sql2 appendFormat:@"?%@",comma];
                    [args addObject:value];
                }
            }
        }
    }];
    [sql1 deleteCharactersInRange:NSMakeRange(sql1.length-comma.length, comma.length)];
    [sql2 deleteCharactersInRange:NSMakeRange(sql2.length-comma.length,comma.length)];
    [sql1 appendString:@")"];
    [sql2 appendString:@")"];
    NSString *sql=[NSString stringWithFormat:@"%@%@",sql1,sql2];
    if ([sql rangeOfString:@"()"].location==NSNotFound) {
        [modelDatabase executeUpdate:sql arguments:args];
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
    NSString *primaryKey=[self _primaryKey];
    id primaryValue =[model valueForKey:primaryKey];
    if ((!primaryValue)||[primaryValue isKindOfClass:NSNull.class]) {
        OOModelLog(@"%@'s primary value is not exist!",model);
        return;
    }
    NSString *databasePrimaryKey=[self _columnsByPropertyKey][primaryKey];
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
    NSString *table=[self _table];
    NSMutableString *sql=nil;
    NSMutableArray *args=[NSMutableArray array];
    NSString *and=@",";
    NSString *preSql=[NSString stringWithFormat:@"update %@ set ",table];
    sql=[preSql mutableCopy];
    NSString *primaryKey=[self _primaryKey];
    NSDictionary *modelDictionary=[model dictionary];
    [[[model.class _columnsByPropertyKey]oo_dictionaryByRemoveKeys:@[primaryKey]] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSString *  _Nonnull column, BOOL * _Nonnull stop) {
        @autoreleasepool {
            id value=[modelDictionary objectForKey:propertyKey];
            if (value&&![value isKindOfClass:NSNull.class]) {
                NSValueTransformer *valueTransformer=[model.class _databaseValueTransformerForKey:propertyKey];
                if (valueTransformer) {
                    value=[valueTransformer transformedValue:value];
                }
                if (value&&![value isKindOfClass:NSNull.class]) {
                    [args addObject:value];
                    [sql appendFormat:@"%@=?%@",column,and];
                }
            }
        }
    }];
    [sql deleteCharactersInRange:NSMakeRange(sql.length-and.length, and.length)];
    if ([sql length]<=preSql.length) {
        return;
    }
    id primaryValue=[modelDictionary objectForKey:primaryKey];
    NSValueTransformer *valueTransformer=[model.class _databaseValueTransformerForKey:primaryKey];
    if (valueTransformer) {
        primaryValue=[valueTransformer transformedValue:primaryValue];
    }
    NSString *databasePrimaryKey=[self _columnsByPropertyKey][primaryKey];
    if (primaryValue&&![primaryValue isKindOfClass:NSNull.class]) {
        NSString *whereSql=[NSString stringWithFormat:@" where %@=?",databasePrimaryKey];
        [sql appendString:whereSql];
        [args addObject:primaryValue];
        if (sql.length>preSql.length+whereSql.length) {
            [modelDatabase executeUpdate:sql arguments:args];
        }
    }
}

#pragma mark --
#pragma mark -- validate once

+ (void)_validateOnce{
    dispatch_once_t onceToken=[objc_getAssociatedObject(self, @selector(_validateOnce)) integerValue];
    if (!onceToken) {
        dispatch_once(&onceToken, ^{
            NSParameterAssert([[self _columnsByPropertyKey] isKindOfClass:NSDictionary.class]);
            NSParameterAssert([[self _columnTypesByPropertyKey] isKindOfClass:NSDictionary.class]);
            NSParameterAssert([[self _table] isKindOfClass:NSString.class]);
            [[self _columnsByPropertyKey] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                NSParameterAssert([key isKindOfClass:NSString.class]);
                NSParameterAssert([obj isKindOfClass:NSString.class]);
            }];
            [[self _columnTypesByPropertyKey] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                NSParameterAssert([key isKindOfClass:NSString.class]);
                NSParameterAssert([obj isKindOfClass:NSNumber.class]);
                NSParameterAssert([obj integerValue]>=0&&[obj integerValue]<OODatabaseColumnTypeBlob);
            }];
        });
        objc_setAssociatedObject(self, @selector(_validateOnce), @(onceToken), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark --
#pragma mark -- create

+ (void)_createTableIfNeed{
    if ([self _tableLastCreateTime]==modelDatabaseOpenTime) {
        return;
    }
    [self _createTable];
}

+ (void)_createTable{
    [self _validateOnce];
    NSString *table=[self _table];
    if (![self _checkTable:table]) {
        NSString *primaryKey=[self _primaryKey];
        NSString *sql=nil;
        if (primaryKey) {
            NSString *databasePrimaryKey=[self _columnsByPropertyKey][primaryKey];
            NSNumber *typeNumber=[self _columnTypesByPropertyKey][primaryKey];
            NSParameterAssert(typeNumber);
            OODatabaseColumnType type=typeNumber.integerValue;
            NSString * primaryType=_columnTypeWithType(type);
            sql=[NSString stringWithFormat:@"create table if not exists '%@' ('id' integer not null primary key autoincrement,'%@' %@ not null unique)",table,databasePrimaryKey,primaryType];
        }else{
            sql=[NSString stringWithFormat:@"create table if not exists '%@' ('id' integer not null primary key autoincrement)",table];
        }
        [modelDatabase executeUpdate:sql arguments:nil];
    }
    [self _addColumns];
    [self _addIndexes];
}

+ (void)_addColumns{
    NSString *table = [self _table];
    NSDictionary *columnsByPropertyKey=[self _columnsByPropertyKey];
    [columnsByPropertyKey enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSString *  _Nonnull column, BOOL * _Nonnull stop) {
        if (![self _checkTable:table column:column]) {
            OODatabaseColumnType type=[[self _columnTypesByPropertyKey][key] integerValue];
            NSString *columnType=_columnTypeWithType(type);
            NSString *sql=[NSString stringWithFormat:@"alter table '%@' add column '%@' %@",table,column,columnType];
            [modelDatabase executeUpdate:sql arguments:nil];
        }
    }];
}

+ (void)_addIndexes{
    NSArray *indexes=[self _indexesKeys];
    NSParameterAssert([indexes isKindOfClass:NSArray.class]||!indexes);
    NSDictionary *columnsByPropertyKey=[self _columnsByPropertyKey];
    NSString *table=[self _table];
    NSMutableArray *databaseIndexes=[NSMutableArray array];
    [indexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSParameterAssert([obj isKindOfClass:NSString.class]);
        NSString *index=columnsByPropertyKey[obj];
        NSParameterAssert([index isKindOfClass:NSString.class]);
        [databaseIndexes addObject:index];
    }];
    [databaseIndexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self _chekTable:table index:obj]) {
            NSString *index=[NSString stringWithFormat:@"%@_%@_index",table,obj];
            NSString *sql=[NSString stringWithFormat:@"create index %@ on %@(%@)",index,table,obj];
            [modelDatabase executeUpdate:sql arguments:nil];
        }
    }];
    [self _setTableLastCreateTime:modelDatabaseOpenTime];
}

#pragma mark --
#pragma mark -- check func

+ (BOOL)_checkTable:(NSString*)table{
    NSString * sql=@"select * from sqlite_master where tbl_name=? and type='table'";
    NSArray * sets=[modelDatabase executeQuery:sql arguments:@[table]];
    if (sets.count>0) {
        return YES;
    }else{
        return NO;
    }
}

+ (BOOL)_checkTable:(NSString*)table column:(NSString*)column{
    BOOL ret=NO;
    NSString * sql=@"select sql from sqlite_master where tbl_name=? and type='table'";
    NSArray * sets=[modelDatabase executeQuery:sql arguments:@[table]];
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
    NSArray * sets=[modelDatabase executeQuery:sql arguments:@[table]];
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
    NSArray * sets=[modelDatabase executeQuery:sql arguments:@[value]];
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

+ (NSDictionary*)_dictionaryWithDatabaseDictionary:(NSDictionary*)databaseDictionary{
    if (![databaseDictionary isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSDictionary *databasePropertyKeysByColumn=[self _propertyKeysByColumn];
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    [databaseDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        @autoreleasepool {
            key=databasePropertyKeysByColumn[key];
            if (key&&![obj isKindOfClass:NSNull.class]) {
                NSValueTransformer *valueTransformer=[self.class _databaseValueTransformerForKey:key];
                if (valueTransformer) {
                    obj=[valueTransformer reverseTransformedValue:obj];
                }
                if (obj) {
                    [dictionary setObject:obj forKey:key];
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
        NSDictionary * columnsByPropertyKey=[self.class databaseColumnsByPropertyKey];
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

+ (NSString*)_table{
    NSString * table=objc_getAssociatedObject(self, @selector(_table));
    if (!table) {
        table=[self.class databaseTableName];
        objc_setAssociatedObject(self, @selector(_table),table, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return table;
}

+ (NSString*)_primaryKey{
    NSString * primaryKey=objc_getAssociatedObject(self, @selector(_primaryKey));
    if (!primaryKey) {
        if (![self.class respondsToSelector:@selector(databasePrimaryKey)]) {
            return nil;
        }
        primaryKey=[self.class databasePrimaryKey];
        if (primaryKey) {
            NSParameterAssert([primaryKey isKindOfClass:NSString.class]);
        }
        objc_setAssociatedObject(self, @selector(_primaryKey),primaryKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return primaryKey;
}

+ (NSArray*)_indexesKeys{
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
