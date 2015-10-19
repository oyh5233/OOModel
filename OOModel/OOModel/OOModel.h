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

+ (NSDictionary*)jsonKeyPathsByPropertyKey;

@optional

+ (NSValueTransformer*)jsonValueTransformerForKey:(NSString*)key;

@end

@protocol OODatabaseSerializing <NSObject>

+ (NSDictionary*)databaseColumnsByPropertyKey;

+ (NSDictionary*)databaseColumnTypesByPropertyKey;

+ (NSString*)databaseTableName;

@optional

+ (NSString*)databasePrimaryKey;

+ (NSArray*)databaseIndexesKeys;

+ (NSValueTransformer*)databaseValueTransformerForKey:(NSString*)key;

@end

@protocol OOManagerSerializing <NSObject>

+ (NSString*)managerMapTableName;

+ (NSString*)managerPrimaryKey;

@end

@interface OOModel : NSObject

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

@end

@interface OOModel (OODatabaseSerializing)
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

+ (BOOL)openDatabaseWithFile:(NSString*)file;

@end

@interface OOModel (OOManagerSerializing)

+ (NSArray*)oo_modelsWithDictionaries:(NSArray*)dictionaryies;

+ (instancetype)oo_modelWithDictionary:(NSDictionary*)dictionary;

- (BOOL)oo_mergeWithDictionary:(NSDictionary*)dictionary;


+ (NSArray*)oo_modelsWithJsonDictionaries:(NSArray *)jsonDictionaryies;

+ (instancetype)oo_modelWithJsonDictionary:(NSDictionary*)jsonDictionary;

- (BOOL)oo_mergeWithJsonDictionary:(NSDictionary*)jsonDictionary;
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
