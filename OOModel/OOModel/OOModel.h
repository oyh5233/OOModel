//
//  OOModel.h
//  OOModel
//

#import <Foundation/Foundation.h>
#import "NSDictionary+OOModelAddition.h"
#import "OOValueTransformer.h"

#define OOModelLog(fmt, ...) NSLog((@"[Function %s][Line %d] " fmt),__FUNCTION__,__LINE__, ##__VA_ARGS__)

typedef NS_ENUM(NSInteger,OODatabaseColumnType) {
    OODatabaseColumnTypeText,
    OODatabaseColumnTypeInteger,
    OODatabaseColumnTypeReal,
    OODatabaseColumnTypeBlob
};

@protocol OOJsonSerializing <NSObject>

+ (NSDictionary*)jsonKeyPathsByPropertyKeys;

@optional

+ (NSValueTransformer*)jsonValueTransformerForKey:(NSString*)key;

@end

@protocol OODatabaseSerializing <NSObject>

+ (NSDictionary*)databaseColumnsByPropertyKeys;

+ (NSDictionary*)databaseColumnTypesByPropertyKeys;

+ (NSString*)databaseTableName;

@optional

+ (NSString*)databasePrimaryKey;

+ (NSArray*)databaseIndexesKeys;

+ (NSValueTransformer*)databaseValueTransformerForKey:(NSString*)key;

@end

@protocol OOManagedObject <NSObject>

+ (NSString*)managedPrimaryKey;

+ (NSString*)managedMapTableName;


@end

@interface OOModel : NSObject <NSCoding>

+ (NSArray *)modelsWithDictionaries:(NSArray*)dictionaries;

+ (instancetype)modelWithDictionary:(NSDictionary*)dictionary;

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

- (BOOL)mergeWithDictionary:(NSDictionary*)dictionary;

- (BOOL)mergeWithModel:(OOModel*)model;

- (NSDictionary*)dictionary;

+ (NSArray *)propertyKeys;

@end

@interface OOModel (OOJsonSerializing)

+ (NSArray*)modelsWithJsonDictionaries:(NSArray*)jsonDictionaries;

+ (instancetype)modelWithJsonDictionary:(NSDictionary*)jsonDictionary;

- (instancetype)initWithJsonDictionary:(NSDictionary*)jsonDictionary;

- (BOOL)mergeWithJsonDictionary:(NSDictionary*)jsonDictionary;

- (NSDictionary*)jsonDictionary;

+ (NSString*)propertyKeyForJsonKeyPath:(NSString*)keyPath;

+ (NSString*)jsonKeyPathForPropertyKey:(NSString*)propertyKey;

+ (id)valueWithJsonValue:(id)value forPropertyKey:(NSString*)propertyKey;

+ (id)jsonValueWithValue:(id)value forPropertyKey:(NSString*)propertyKey;

@end

@interface OOModel (OODatabaseSerializing)
/**
 *  open database in file path
 *
 *  @param file file path
 *
 *  @return success or fail
 */
+ (BOOL)openDatabaseWithFile:(NSString*)file;
/**
 *  close database
 *
 *  @return success or fail
 */
+ (BOOL)closeDatabase;

/**
 *  <#Description#>
 *
 *  @param sql       sql after 'where '
 *  @param arguments <#arguments description#>
 *
 *  @return <#return value description#>
 */
+ (NSArray*)modelsWithSql:(NSString*)sql arguments:(NSArray*)arguments;
/**
 *  <#Description#>
 *
 *  @param sql       sql after 'where '
 *  @param arguments <#arguments description#>
 *
 *  @return <#return value description#>
 */
+ (instancetype)modelWithSql:(NSString*)sql arguments:(NSArray*)arguments;
/**
 *  <#Description#>
 *
 *  @param sql       sql after 'where '
 *  @param arguments <#arguments description#>
 *
 *  @return <#return value description#>
 */
+ (void)deleteModelsWithSql:(NSString*)sql arguments:(NSArray*)arguments;

+ (void)updateModels:(NSArray*)models;

- (void)update;

- (NSDictionary*)databaseDictionary;

+ (NSString*)propertyKeyForDatabaseColumn:(NSString*)column;

+ (NSString*)databaseColumnForPropertyKey:(NSString*)propertyKey;

+ (id)valueWithDatabaseValue:(id)value forPropertyKey:(NSString*)propertyKey;

+ (id)databaseValueWithValue:(id)value forPropertyKey:(NSString*)propertyKey;

@end

@interface OOModel (OOManagedObject)

+ (NSArray*)oo_modelsWithDictionaries:(NSArray*)dictionaryies;

+ (instancetype)oo_modelWithDictionary:(NSDictionary*)dictionary;

- (BOOL)oo_mergeWithDictionary:(NSDictionary*)dictionary;

+ (NSArray*)oo_modelsWithJsonDictionaries:(NSArray *)jsonDictionaryies;

+ (instancetype)oo_modelWithJsonDictionary:(NSDictionary*)jsonDictionary;

- (BOOL)oo_mergeWithJsonDictionary:(NSDictionary*)jsonDictionary;

+ (void)oo_updateModels:(NSArray*)models;

- (void)oo_update;
/**
 *
 *  <#Description#>
 *
 *  @param sql       sql after 'where ' 
 *  @param arguments <#arguments description#>
 *
 *  @return <#return value description#>
 */
+ (NSArray*)oo_modelsWithSql:(NSString*)sql arguments:(NSArray*)arguments;
/**
 *
 *  <#Description#>
 *
 *  @param sql       sql after 'where '
 *  @param arguments <#arguments description#>
 *
 *  @return <#return value description#>
 */
+ (instancetype)oo_modelWithSql:(NSString*)sql arguments:(NSArray*)arguments;


@end
