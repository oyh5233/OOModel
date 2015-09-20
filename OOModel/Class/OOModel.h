//
//  OOModel.h
//  iPhoneAPP
//
//  Created by oo on 15/9/1.
//  Copyright (c) 2015 oo. All rights reserved.
//
/**
 
 */
#import "Mantle.h"
#import "FMDB.h"
typedef NS_ENUM(NSInteger, OO_DatabaseColumnType) {
    OO_DatabaseColumnTypeText,
    OO_DatabaseColumnTypeInteger,
    OO_DatabaseColumnTypeReal,
    OO_DatabaseColumnTypeBlob,
};

@protocol OOModelDatabaseSerializing <MTLJSONSerializing>

@required
/**
 *  managed table name,table will auto create if not exist
 *
 *  @return talble name
 */
+ (nonnull NSString*)oo_databaseTableName;
/**
 *  column name && type,columns will auto create if not exist
 *  ex. @{
 *         @"uid":@(OO_DatabaseColumnTypeInteger),
 *         @"uname":@(OO_DatabaseColumnTypeText)
 *      }
 *
 *  @return dict of column's type for column's name
 */
+ (nonnull NSDictionary*)oo_databaseColumnTypeForKeys;

@optional
/**
 *  this primary key is just unique,used to manager model.table's primary key is 'id' integer autoincrement
 *
 *  @return primary key
 */
+ (nullable NSString*)oo_databasePrimaryKey;
/**
 *  index will be auto create,when column is in this set
 *  you should not create a index for primaryKey
 *  @return set of indexed column name
 */
+ (nullable NSSet*)oo_databaseColumnIndexesKeys;
/**
 *  transformer for model && database
 *
 *  @param key column name property key
 *
 *  @return transformer
 */
+ (nullable NSValueTransformer* )oo_databaseTransformerForKey:(nonnull NSString*)key;

@end

@interface OOModel : MTLModel<OOModelDatabaseSerializing>
/**
 *  at first,you should open a DB file
 *
 *  @param complete      complete
 *  @param file          database path
 *  @param synchronously synchronously
 */
+ (void)oo_openDatabase:(void(^__nullable)())complete file:(nonnull NSString *)file synchronously:(BOOL)synchronously;
/**
 *  return a model with a dictionary synchronously.if model with same primary key exist in maptable,it will return the model in maptable and refresh model's property with dictionary.if error occur,return nil
 *
 *  @param dictionaryValue dict
 *
 *  @return model or nil
 */
+ (nullable instancetype)oo_modelWithDictionary:(nonnull NSDictionary*)dictionaryValue;
/**
 *  return any model with dictionaries synchronously
 *
 *  @param dictionaryValues dicts
 *
 *  @return array
 */
+ (nullable NSArray*)oo_modelsWithDictionaries:(nonnull NSArray*)dictionaryValues;
/**
 *  ret a model from cache or database
 *
 *  @param sql
 *
 *  @return model or nil
 */
+ (nullable instancetype)oo_modelWithSql:(nonnull NSString*)sql,...;
/**
 *
 *
 *  @param  sql after where;ex. @"uid=? ",@"10000"
 *
 *  @return modes
 */
+ (nullable NSArray*)oo_modelsWithSql:(nonnull NSString*)sql,...;

/**
 *  model from dictionary,if model with same primary key exist in maptable,it will return the model in maptable and refresh model's property with dictionary.if error occur,return nil
 *
 *  @param complete        complete
 *  @param synchronously   sync?
 *  @param dictionaryValue dict
 */
+ (void)oo_model:(void(^__nullable)(id _Nullable model))complete synchronously:(BOOL)synchronously dictionary:(nonnull NSDictionary*)dictionaryValue ;
/**
 *  if model with same primary key exist in maptable,it will return the model in maptable and refresh model's property with dictionary.if error occur,return nil
 *
 *  @param complete         complete
 *  @param synchronously    sync
 *  @param dictionaryValues dicts
 */
+ (void)oo_models:(void (^__nullable)(NSArray * _Nonnull models))complete  synchronously:(BOOL)synchronously dictionaries:(nonnull NSArray *)dictionaryValues;
/**
 *  select models from maptable at first,if not exit,select them from database;
 *
 *  @param complete      complete
 *  @param synchronously sync
 *  @param sql           sql after where ex. @"uid=? ",@"10000"
 */
+ (void)oo_select:(void(^__nonnull)(NSArray * _Nonnull models))complete synchronously:(BOOL)synchronously sql:(nonnull NSString*)sql,...;
/**
 *  delete models
 *
 *  @param complete      complete
 *  @param synchronously sync
 *  @param models        models
 */
+ (void)oo_delete:(void(^__nullable)())complete synchronously:(BOOL)synchronously models:(nonnull NSArray*)models;
/**
 *  delete table
 *
 *  @param complete      complete
 *  @param synchronously sync
 */
+ (void)oo_delete:(void (^__nullable)())complete synchronously:(BOOL)synchronously;
/**
 *
 */
+ (void)oo_inDB:(void(^__nonnull)(FMDatabase * _Nonnull db))block synchronously:(BOOL)synchronously;
@end
