;//
//  OOModel.m
//
//  Created by oo on 15/9/20.
//  Copyright © 2015 oo. All rights reserved.
//

#import "OOModel.h"
#import "MTLReflection.h"
#import "objc/runtime.h"
static FMDatabase * oo_model_database=nil;
static void * k_oo_queue_key=&k_oo_queue_key;
static NSString * const OO_DATABASE_DONT_EXIST=@"database don't exist";
@implementation OOModel
#pragma mark --
#pragma mark -- interface

+ (instancetype)oo_modelWithDictionary:(NSDictionary*)dictionaryValue{
    __block OOModel *retModel=nil;
    [self oo_model:^(id model) {
        retModel=model;
    } synchronously:YES dictionary:dictionaryValue];
    return retModel;
}
+ (nullable instancetype)oo_modelWithSql:(nonnull NSString*)sql,...{
    va_list ap;
    va_start(ap, sql);
    NSMutableArray *args=[NSMutableArray array];
    sql=[NSString stringWithFormat:@"select * from %@ where %@",[self oo_databaseTableName],sql];
    NSInteger argsCount=[self oo_argsCountWithSql:sql];
    for(NSInteger i=0;i<argsCount;i++){
        id arg=va_arg(ap, id);
        if (arg) {
            [args addObject:arg];
        }
    }
    va_end(ap);
    __block OOModel *retModel=nil;
    [self oo_excute:^{
        if (!oo_model_database) {
            [NSException raise:OO_DATABASE_DONT_EXIST format:OO_DATABASE_DONT_EXIST];
            return;
        }
        NSArray * models= [self oo_selectAndSyncWithSql:sql args:args inDB:oo_model_database];
        retModel=models.count>0?[models lastObject]:nil;
    } synchronously:YES];
    return retModel;
}
+ (NSArray*)oo_modelsWithSql:(NSString*)sql,...{
    va_list ap;
    va_start(ap, sql);
    NSMutableArray *args=[NSMutableArray array];
    sql=[NSString stringWithFormat:@"select * from %@ where %@",[self oo_databaseTableName],sql];
    NSInteger argsCount=[self oo_argsCountWithSql:sql];
    for(NSInteger i=0;i<argsCount;i++){
        id arg=va_arg(ap, id);
        if (arg) {
            [args addObject:arg];
        }
    }
    va_end(ap);
    __block NSArray *retModels=[NSArray array];
    [self oo_excute:^{
        if (!oo_model_database) {
            [NSException raise:OO_DATABASE_DONT_EXIST format:OO_DATABASE_DONT_EXIST];
            return;
        }
        retModels=[self oo_selectAndSyncWithSql:sql args:args inDB:oo_model_database];
    } synchronously:YES];
    return retModels;
}

+ (NSArray*)oo_modelsWithDictionaries:(NSArray*)dictionaryValues{
    __block NSArray *retModels=[NSArray array];
    [self oo_models:^(NSArray *models) {
        retModels=models;
    } synchronously:YES dictionaries:dictionaryValues];
    return retModels;
}

+ (void)oo_model:(void(^)(id model))complete synchronously:(BOOL)synchronously dictionary:(NSDictionary*)dictionaryValue{
    [self oo_excute:^{
        if (!oo_model_database) {
            [NSException raise:OO_DATABASE_DONT_EXIST format:OO_DATABASE_DONT_EXIST];
            if(complete) {
                complete(nil);
            }
            return;
        }
        OOModel * model=[self oo_modelWithDictionary_inner:dictionaryValue];
        if(complete) {
            complete(model);
        }
    } synchronously:synchronously];
}

+ (void)oo_models:(void (^)(NSArray *models))complete synchronously:(BOOL)synchronously dictionaries:(NSArray *)dictionaryValues{
    [self oo_excute:^{
        NSMutableArray *models=[NSMutableArray array];
        if (!oo_model_database) {
            [NSException raise:OO_DATABASE_DONT_EXIST format:OO_DATABASE_DONT_EXIST];
            if(complete) {
                complete(models);
            }
            return;
        }
        if ([dictionaryValues isKindOfClass:[NSArray class]]) {
            for(NSDictionary * dictionaryValue in dictionaryValues){
                @autoreleasepool {
                    OOModel * model=[self oo_modelWithDictionary_inner:dictionaryValue];
                    [models addObject:model];
                }
            }
        }
        if(complete) {
            complete(models);
        }
    } synchronously:synchronously];
}
+ (void)oo_select:(void(^)(NSArray *models))complete synchronously:(BOOL)synchronously sql:(NSString*)sql,...{
    va_list ap;
    va_start(ap, sql);
    NSMutableArray *args=[NSMutableArray array];
    sql=[NSString stringWithFormat:@"select * from %@ where %@",[self oo_databaseTableName],sql];
    NSInteger argsCount=[self oo_argsCountWithSql:sql];
    for(NSInteger i=0;i<argsCount;i++){
        id arg=va_arg(ap, id);
        if (arg) {
            [args addObject:arg];
        }
    }
    va_end(ap);
    [self oo_excute:^{
        if (!oo_model_database) {
            [NSException raise:OO_DATABASE_DONT_EXIST format:OO_DATABASE_DONT_EXIST];
            if(complete) {
                complete([NSArray array]);
            }
            return;
        }
        NSArray *retModel=[self oo_selectAndSyncWithSql:sql args:args inDB:oo_model_database];
        if(complete) {
            complete(retModel);
        }
    } synchronously:synchronously];
    
}

+ (void)oo_delete:(void(^)())complete synchronously:(BOOL)synchronously models:(NSArray*)models{
    [self oo_excute:^{
        if (!oo_model_database) {
            [NSException raise:OO_DATABASE_DONT_EXIST format:OO_DATABASE_DONT_EXIST];
            if(complete) {
                complete(nil);
            }
            return;
        }
        NSString *tableName=[self oo_databaseTableName];
        if(![self oo_checkTable:tableName inDB:oo_model_database]){
            return;
        }
        for(OOModel * model in models){
            @autoreleasepool {
                [[model class] oo_deleteModel:model inDB:oo_model_database];
            }
        }
        if(complete) {
            complete();
        }
    } synchronously:synchronously];
}

+ (void)oo_delete:(void (^)())complete synchronously:(BOOL)synchronously{
    [self oo_excute:^{
        if (!oo_model_database) {
            [NSException raise:OO_DATABASE_DONT_EXIST format:OO_DATABASE_DONT_EXIST];
            if(complete) {
                complete(nil);
            }
            return;
        }
        NSString *tableName=[self oo_databaseTableName];
        if ([self oo_checkTable:tableName inDB:oo_model_database]) {
            NSString *sql=[NSString stringWithFormat:@"drop table %@",tableName];
            [oo_model_database executeUpdate:sql];
        }
        [self oo_setTableCreated:NO];
        if (complete) {
            complete();
        }
    } synchronously:synchronously];
}

+ (void)oo_inDB:(void(^__nonnull)(FMDatabase * _Nonnull db))block synchronously:(BOOL)synchronously{
    [self oo_excute:^{
        if (!oo_model_database) {
            [NSException raise:OO_DATABASE_DONT_EXIST format:OO_DATABASE_DONT_EXIST];
        }
        if (block) {
            block(oo_model_database);
        }
    } synchronously:YES];
}
#pragma mark --
#pragma mark -- database
+ (void)oo_openDatabase:(void(^)())complete file:(NSString*)file synchronously:(BOOL)synchronously{
    [self oo_excute:^{
        if (oo_model_database) {
            if (file&&[[oo_model_database databasePath] isEqualToString:file]) {
                return;
            }
            [oo_model_database close];
        }
        if (file) {
            oo_model_database=[FMDatabase databaseWithPath:file];
            [oo_model_database open];
        }
    } synchronously:synchronously];
}

+ (void)oo_createTable:(Class)modelClass InDB:(FMDatabase*)db{
    if ([self oo_isTableCreated]) {
        return;
    }
    [self oo_setTableCreated:YES];
    NSString *tableName=[modelClass oo_databaseTableName];
    NSDictionary *columnsAndTypes=[modelClass oo_databaseColumnTypeForKeys];
    NSDictionary *typesDictionary=@{
                                    @(OO_DatabaseColumnTypeText):@"text",
                                    @(OO_DatabaseColumnTypeInteger):@"integer",
                                    @(OO_DatabaseColumnTypeReal):@"real",
                                    @(OO_DatabaseColumnTypeBlob):@"blob"
                                    };
    NSString *primaryKey=[modelClass oo_databasePrimaryKey];
    NSString * primaryType=[typesDictionary objectForKey:[columnsAndTypes objectForKey:primaryKey]];
    __block NSString *sql=nil;
    if(![self oo_checkTable:tableName inDB:db]){
        if(primaryKey) {
            sql=[NSString stringWithFormat:@"create table if not exists '%@' ('id' integer not null primary key autoincrement,'%@' %@ not null unique)",tableName,primaryKey,primaryType];
        }else{
            sql=[NSString stringWithFormat:@"create table if not exists '%@' ('id' integer not null primary key autoincrement)",tableName];
        }
        [db executeUpdate:sql];
    }
    if(primaryKey) {
        columnsAndTypes=[columnsAndTypes mtl_dictionaryByRemovingValuesForKeys:@[primaryKey]];
    }
    [columnsAndTypes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        @autoreleasepool {
            if(![modelClass oo_checkTable:tableName column:key inDB:db]){
                sql=[NSString stringWithFormat:@"alter table '%@' add column '%@' %@",tableName,key,[typesDictionary objectForKey:obj]];
                [db executeUpdate:sql];
            }
        }
    }];
    NSSet *indexes=[[modelClass class] oo_databaseColumnIndexesKeys];
    [indexes enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        @autoreleasepool {
            NSString *indexName=[NSString stringWithFormat:@"%@_%@_index",tableName,obj];
            if(![[modelClass class] oo_chekTable:tableName index:indexName inDB:db]){
                [[modelClass class] oo_createIndexAtTable:tableName index:indexName column:obj inDB:db];
            }
        }
    }];
}
+ (void)oo_createIndexAtTable:(NSString*)table index:(NSString*)index column:(NSString*)column inDB:(FMDatabase*)db{
    NSString *sql=[NSString stringWithFormat:@"create index %@ on %@(%@)",index,table,column];
    [db executeUpdate:sql];
}

+ (NSArray*)oo_selectAndSyncWithSql:(NSString*)sql args:(NSArray*)args inDB:(FMDatabase*)db{
    NSArray *models=[NSArray array];
    @try {
        models=[self oo_selectWithSql:sql args:args inDB:oo_model_database];
        NSMutableArray *retModels=[NSMutableArray array];
        for(OOModel * model in models){
            @autoreleasepool {
                NSString *primaryKey=[[model class]oo_databasePrimaryKey];
                if(primaryKey){
                    id primaryValue=[model oo_primaryValue];
                    OOModel * mapTableModel=[[[model class]oo_mapTable] objectForKey:primaryValue];
                    if(mapTableModel) {
                        [retModels addObject:mapTableModel];
                    }else{
                        [[[model class]oo_mapTable] setObject:model forKey:primaryValue];
                        [retModels addObject:model];
                    }
                }else{
                    [retModels addObject:model];
                }
            }
        }
        return retModels;
    }
    @catch (NSException *exception) {
        return models;
    }
}
+ (NSArray *)oo_selectWithSql:(NSString*)sql args:(NSArray*)args inDB:(FMDatabase*)db {
    NSMutableArray *models=[NSMutableArray array];
    [self oo_createTable:self InDB:oo_model_database];
    FMResultSet *set=[db executeQuery:sql withArgumentsInArray:args];
    while ([set next]) {
        @autoreleasepool {
            NSMutableDictionary *modelDict=[NSMutableDictionary dictionary];
            [[set resultDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![self oo_checkIDIfNilOrNull:obj]) {
                    NSValueTransformer *valueTransformer=[self oo_databaseTransformerForKey:key];
                    if(valueTransformer) {
                        obj=[valueTransformer reverseTransformedValue:obj];
                    }
                    if(![self oo_checkIDIfNilOrNull:obj]) {
                        [modelDict setObject:obj forKey:key];
                    }
                }
            }];
            if(modelDict.count>0) {
                NSError *error=nil;
                OOModel *model=[self modelWithDictionary:[modelDict mtl_dictionaryByRemovingValuesForKeys:@[@"id"]] error:&error];
                if (error) {
                    [NSException raise:error.domain format:@"%@",error.localizedDescription];
                }else{
                    [models addObject:model];
                }
            }
        }
    }
    [set close];
    return models;
}

+ (void)oo_updateModels:(NSArray*)models inDB:(FMDatabase*)db{
    @try {
        for(OOModel * model in models){
            @autoreleasepool {
                [self oo_createTable:[model class] InDB:db];
                NSString *tableName=[[model class] oo_databaseTableName];
                NSString * primaryKey=[[model class] oo_databasePrimaryKey];
                if(primaryKey) {
                    id primaryValue=[model oo_primaryValue];
                    NSValueTransformer *valueTransformer=[[model class]oo_databaseTransformerForKey:primaryKey];
                    if(valueTransformer) {
                        primaryValue=[valueTransformer transformedValue:primaryValue];
                        [self oo_checkIDIfNilOrNullAndRaiseException:primaryValue];
                    }
                    if([self oo_checkTable:tableName primaryKey:primaryKey primaryValue:primaryValue inDB:db]) {
                        [self oo_updateModel:model inDB:db];
                    }else{
                        [self oo_insertModel:model inDB:db];
                    }
                }else{
                    [self oo_insertModel:model inDB:db];
                }
                
            }
        }
    }
    @catch (NSException *exception) {
        
    }
}
+ (void)oo_updateModel:(OOModel*)model inDB:(FMDatabase*)db{
    @try {
        NSString *and=@",";
        NSString *tableName=[[model class]oo_databaseTableName];
        NSString *primaryKey=[[model class]oo_databasePrimaryKey];
        if(!primaryKey) {
            return;
        }
        NSMutableString *sql=[NSMutableString string];
        NSMutableArray *args=[NSMutableArray array];
        NSString *preSql=[NSString stringWithFormat:@"update %@ set ",tableName];
        sql=[preSql mutableCopy];
        [[[[model class]oo_databaseColumnTypeForKeys]mtl_dictionaryByRemovingValuesForKeys:@[primaryKey]] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            @autoreleasepool {
                obj=[[model dictionaryValue]objectForKey:key];
                if(![self oo_checkIDIfNilOrNull:obj]) {
                    NSValueTransformer *valueTransformer=[[model class] oo_databaseTransformerForKey:key];
                    if(valueTransformer) {
                        obj=[valueTransformer transformedValue:obj];
                    }
                    if(![self oo_checkIDIfNilOrNull:obj]) {
                        [args addObject:obj];
                        [sql appendFormat:@"%@=?%@",key,and];
                    }
                }
            }
        }];
        [sql deleteCharactersInRange:NSMakeRange(sql.length-and.length, and.length)];
        if([sql length]<=preSql.length) {
            return;
        }
        id primaryValue=[model oo_primaryValue];
        NSValueTransformer *valueTransformer=[[model class]oo_databaseTransformerForKey:primaryKey];
        if(valueTransformer) {
            primaryValue=[valueTransformer transformedValue:primaryValue];
        }
        [self oo_checkIDIfNilOrNullAndRaiseException:primaryValue];
        if([primaryValue isKindOfClass:[NSString class]]) {
            [sql appendFormat:@" where %@ like ?",primaryKey];
        }else{
            [sql appendFormat:@" where %@=?",primaryKey];
        }
        [args addObject:primaryValue];
        [db executeUpdate:sql withArgumentsInArray:args];
    }
    @catch (NSException *exception) {
        
    }
    
}

+ (void)oo_insertModel:(OOModel*)model inDB:(FMDatabase*)db{
    @try {
        NSString *primaryKey=[[model class]oo_databasePrimaryKey];
        if (primaryKey) {
            id primaryValue=[model oo_primaryValue];
            if ([self oo_checkIDIfNilOrNullAndRaiseException:primaryValue]) {
                return;
            }
            NSValueTransformer *valueTransformer=[[model class] oo_databaseTransformerForKey:primaryKey];
            if(valueTransformer) {
                primaryValue=[valueTransformer transformedValue:primaryValue];
                if([self oo_checkIDIfNilOrNullAndRaiseException:primaryValue]){
                    return;
                }
            }
        }
        NSString *comma=@",";
        NSString *tableName=[[model class]oo_databaseTableName];
        NSMutableString *sql1=[NSMutableString string];
        NSMutableString *sql2=[NSMutableString string];
        NSMutableArray *args=[NSMutableArray array];
        [sql1 appendFormat:@"insert into %@ (",tableName];
        [sql2 appendString:@" values ("];
        [[[model class]oo_databaseColumnTypeForKeys] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            @autoreleasepool {
                obj=[[model dictionaryValue]objectForKey:key];
                if(![self oo_checkIDIfNilOrNull:obj]) {
                    NSValueTransformer *valueTransformer=[[model class] oo_databaseTransformerForKey:key];
                    if(valueTransformer) {
                        obj=[valueTransformer transformedValue:obj];
                    }
                    if(![self oo_checkIDIfNilOrNull:obj]) {
                        [sql1 appendFormat:@"%@%@",key,comma];
                        [sql2 appendFormat:@"?%@",comma];
                        [args addObject:obj];
                    }
                }
            }
        }];
        [sql1 deleteCharactersInRange:NSMakeRange(sql1.length-comma.length, comma.length)];
        [sql2 deleteCharactersInRange:NSMakeRange(sql2.length-comma.length,comma.length)];
        [sql1 appendString:@")"];
        [sql2 appendString:@")"];
        
        NSString *sql=[NSString stringWithFormat:@"%@%@",sql1,sql2];
        if([sql rangeOfString:@"()"].location==NSNotFound) {
            [db executeUpdate:sql withArgumentsInArray:args];
        }
    }
    @catch (NSException *exception) {
        
    }
}

+ (void)oo_deleteModel:(OOModel*)model inDB:(FMDatabase*)db{
    @try {
        NSString *tableName=[[model class]oo_databaseTableName];
        NSString *primaryKey=[[model class]oo_databasePrimaryKey];
        NSMutableString *sql=[NSMutableString string];
        NSMutableArray *args=[NSMutableArray array];
        if(primaryKey) {
            id primaryValue=[model oo_primaryValue];
            if ([self oo_checkIDIfNilOrNullAndRaiseException:primaryValue]) {
                return;
            }
            NSValueTransformer *valueTransformer=[[model class]oo_databaseTransformerForKey:primaryKey];
            if(valueTransformer) {
                primaryValue=[valueTransformer transformedValue:primaryValue];
            }
            if([self oo_checkIDIfNilOrNullAndRaiseException:primaryValue]) {
                return;
            }else{
                if([primaryValue isKindOfClass:[NSString class]]) {
                    [sql appendFormat:@"delete * from %@ where %@ like ?",tableName,primaryKey];
                }else{
                    [sql appendFormat:@"delete * from %@ where %@=?",tableName,primaryKey];
                }
                [args addObject:primaryValue];
            }
        }else{
            NSString *preSql=[NSString stringWithFormat:@"delete * from %@ where ",tableName];
            [sql appendString:preSql];
            NSString *and=@" and ";
            [[[model class]oo_databaseColumnTypeForKeys] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                @autoreleasepool {
                    obj=[[model dictionaryValue]objectForKey:key];
                    if(![self oo_checkIDIfNilOrNull:obj]) {
                        NSValueTransformer *valueTransformer=[[model class]oo_databaseTransformerForKey:key];
                        if(valueTransformer) {
                            obj=[valueTransformer transformedValue:obj];
                        }
                        if(![self oo_checkIDIfNilOrNull:obj]) {
                            if([obj isKindOfClass:[NSString class]]) {
                                [sql appendFormat:@" %@ like ?%@",key,and];
                            }else{
                                [sql appendFormat:@" %@=?%@",key,and];
                            }
                            [args addObject:obj];
                        }
                        [sql deleteCharactersInRange:NSMakeRange(sql.length-and.length, and.length)];
                    }
                }
                
            }];
            if(sql.length<=preSql.length) {
                return;
            }
        }
        [db executeUpdate:sql];
    }
    @catch (NSException *exception) {
        
    }
}

#pragma mark --
#pragma mark -- check table

+ (BOOL)oo_checkTable:(NSString*)table primaryKey:(NSString*)key primaryValue:(id)value inDB:(FMDatabase*)db{
    NSString *sql=[NSString stringWithFormat:@"select * from %@ where %@=?",table,key];
    FMResultSet *set=[db executeQuery:sql,value];
    if([set next]) {
        [set close];
        return YES;
    }
    [set close];
    return NO;
}

+ (BOOL)oo_checkTable:(NSString*)table inDB:(FMDatabase*)db{
    NSString * sql=@"select * from sqlite_master where tbl_name=? and type='table'";
    FMResultSet *set=[db executeQuery:sql,table];
    if([set next]) {
        [set close];
        return YES;
    }
    [set close];
    return NO;
}

+ (BOOL)oo_checkTable:(NSString*)table column:(NSString*)column inDB:(FMDatabase*)db{
    BOOL exist=NO;
    NSString * sql=@"select sql from sqlite_master where tbl_name=? and type='table'";
    FMResultSet *set=[db executeQuery:sql,table];
    while ([set next]) {
        sql=[set stringForColumn:@"sql"];
        if(sql&&[sql rangeOfString:column].location!=NSNotFound) {
            exist=YES;
            break;
        }
    }
    [set close];
    return exist;
}

+ (BOOL)oo_chekTable:(NSString*)table index:(NSString*)index inDB:(FMDatabase*)db{
    BOOL exist=NO;
    NSString * sql=@"select * from sqlite_master where tbl_name=? and type='index'";
    FMResultSet *set=[db executeQuery:sql,table];
    while([set next]) {
        sql=[set stringForColumn:@"sql"];
        if(sql&&[sql rangeOfString:index].location!=NSNotFound) {
            exist=YES;
            break;
        }
    }
    [set close];
    return exist;
}
#pragma mark --
#pragma mark -- sql args count
+ (NSInteger)oo_argsCountWithSql:(NSString*)sql{
    Ivar ivar=class_getInstanceVariable([oo_model_database class], [@"_db" UTF8String]);
    sqlite3 * sq=(__bridge sqlite3 *)object_getIvar(oo_model_database, ivar);
    int rc                  = 0x00;
    sqlite3_stmt *pStmt     = 0x00;
    if (!pStmt) {
        rc = sqlite3_prepare_v2(sq, [sql UTF8String], -1, &pStmt, 0);
        if (SQLITE_OK != rc) {
            sqlite3_finalize(pStmt);
            return 0;
        }
    }
    return sqlite3_bind_parameter_count(pStmt);
}
#pragma mark --
#pragma mark -- database delegate

+ (NSString*)oo_databasePrimaryKey{
    return nil;
}

+ (NSDictionary*)oo_databaseColumnTypeForKeys{
    return nil;
}

+ (NSString*)oo_databaseTableName{
    return nil;
}

+ (NSValueTransformer*)oo_databaseTransformerForKey:(NSString*)key{
    return nil;
}

+ (NSSet*)oo_databaseColumnIndexesKeys{
    return nil;
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey{
    return nil;
}

#pragma mark --
#pragma mark -- analytics

+ (instancetype)oo_modelWithDictionary_inner:(NSDictionary *)dictionaryValue{
    @try {
        NSError *error=nil;
        OOModel *analyticalModel=[MTLJSONAdapter modelOfClass:self fromJSONDictionary:dictionaryValue error:&error];
        if (error) {
            [NSException raise:error.domain format:@"%@",error.localizedDescription];
            return nil;
        }
        NSString *primaryKey=[[analyticalModel class]oo_databasePrimaryKey];
        if(!primaryKey) {
            [[analyticalModel class] oo_updateModels:@[analyticalModel] inDB:oo_model_database];
            return analyticalModel;
        }
        id primaryValue=[analyticalModel oo_primaryValue];
        OOModel *mapTableModel=[[[analyticalModel class] oo_mapTable] objectForKey:primaryValue];
        if(!mapTableModel) {
            NSString *sql=nil;
            NSString *databasePrimaryValue=primaryValue;
            NSValueTransformer *valueTransformer=[[analyticalModel class]oo_databaseTransformerForKey:primaryKey];
            if(valueTransformer) {
                databasePrimaryValue=[valueTransformer transformedValue:primaryValue];
                [self oo_checkIDIfNilOrNullAndRaiseException:databasePrimaryValue];
            }
            if([primaryValue isKindOfClass:[NSString class]]) {
                sql=[NSString stringWithFormat:@"select * from %@ where %@ like ?",[self oo_databaseTableName],primaryKey];
            }else{
                sql=[NSString stringWithFormat:@"select * from %@ where %@=?",[self oo_databaseTableName],primaryKey];
            }
            OOModel *databaseModel=analyticalModel;
            NSArray *models=[[analyticalModel class] oo_selectWithSql:sql args:@[databasePrimaryValue] inDB:oo_model_database];
            if(models.count>0) {
                databaseModel=[models lastObject];
            }
            databaseModel=models.count>0?[models lastObject]:nil;
            OOModel *model=nil;
            if(databaseModel) {
                [databaseModel mergeValuesForKeysFromModel:analyticalModel];
                model=databaseModel;
            }else{
                model=analyticalModel;
            }
            [[[model class] oo_mapTable] setObject:model forKey:primaryValue];
            [[model class] oo_updateModels:@[model] inDB:oo_model_database];
            return model;
        }else{
            [mapTableModel mergeValuesForKeysFromModel:analyticalModel];
            [[analyticalModel class] oo_updateModels:@[mapTableModel] inDB:oo_model_database];
            return mapTableModel;
        }
    }
    @catch (NSException *exception) {
        return nil;
    }
}

#pragma mark --
#pragma mark -- override

- (void)mergeValueForKey:(NSString *)key fromModel:(NSObject<MTLModel> *)model {
    SEL selector = MTLSelectorWithCapitalizedKeyPattern("merge", key, "FromModel:");
    if(![self respondsToSelector:selector]) {
        if(model != nil) {
            id value=[model valueForKey:key];
            if(!value) {
                return;
            }
            [self setValue:value forKey:key];
        }
        return;
    }
    IMP imp = [self methodForSelector:selector];
    void (*function)(id, SEL, id<MTLModel>) = (__typeof__(function))imp;
    function(self, selector, model);
}

#pragma mark --
#pragma mark -- sync,async

+ (void)oo_excute:(dispatch_block_t)block synchronously:(BOOL)synchronously{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_set_specific([self oo_queue], k_oo_queue_key, (__bridge void *)self, NULL);
    });
    if(dispatch_get_specific(k_oo_queue_key)) {
        block();
    }else{
        if (synchronously) {
            dispatch_sync([self oo_queue], block);
        }else{
            dispatch_async([self oo_queue], block);
        }
    }
}
#pragma mark --
#pragma mark -- validate value
+ (BOOL)oo_checkIDIfNilOrNullAndRaiseException:(id)value{
    if ([self oo_checkIDIfNilOrNull:value]) {
        [NSException raise:@"primary value should not be nil or null" format:@"%s,%s,%d:primary value should not be nil or null",__FILE__,__func__,__LINE__];
        return YES;
    }
    return NO;
}
+ (BOOL)oo_checkIDIfNilOrNull:(id)value{
    if (!value||[value isKindOfClass:[NSNull class]]) {
        return YES;
    }
    return NO;
}
#pragma mark --
#pragma mark -- setter

+ (void)oo_setTableCreated:(BOOL)isTableCreated{
    objc_setAssociatedObject(self, @selector(oo_isTableCreated), @(isTableCreated), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)oo_isTableCreated{
    BOOL isCreated=objc_getAssociatedObject(self, @selector(oo_isTableCreated));
    return isCreated;
}
#pragma mark --
#pragma mark -- getter
- (id)oo_primaryValue{
    NSString *primaryKey=[[self class] oo_databasePrimaryKey];
    NSString *primaryValue=nil;
    if (primaryKey) {
        primaryValue=[self valueForKeyPath:primaryKey];
        if ([[self class] oo_checkIDIfNilOrNullAndRaiseException:primaryValue]) {
            primaryValue=nil;
        }
    }
    return primaryValue;
}
+ (NSMapTable*)oo_mapTable{
    NSMapTable *mapTable=objc_getAssociatedObject(self, @selector(oo_mapTable));
    if (!mapTable) {
        mapTable=[NSMapTable strongToWeakObjectsMapTable];
        objc_setAssociatedObject(self, @selector(oo_mapTable), mapTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return mapTable;
}
+ (dispatch_queue_t)oo_queue{
    static dispatch_queue_t oo_queue=NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *label=[NSString stringWithFormat:@"operation.%@",NSStringFromClass(self )];
        oo_queue=dispatch_queue_create([label cStringUsingEncoding:NSUTF8StringEncoding], NULL);
    });
    return oo_queue;
}

@end
