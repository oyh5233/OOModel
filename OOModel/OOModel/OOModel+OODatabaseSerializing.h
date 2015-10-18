//
//  OOModel+OODatabaseSerializing.h
//  OOModel
//

#import "OOModel.h"

typedef NS_ENUM(NSInteger,OODatabaseColumnType) {
    OODatabaseColumnTypeText,
    OODatabaseColumnTypeInteger,
    OODatabaseColumnTypeReal,
    OODatabaseColumnTypeBlob
};

@protocol OODatabaseSerializing <NSObject>

+ (NSDictionary*)databaseColumnsByPropertyKey;

+ (NSDictionary*)databaseColumnTypesByPropertyKey;

+ (NSString*)databaseTableName;

@optional

+ (NSString*)databasePrimaryKey;

+ (NSArray*)databaseIndexesKeys;

+ (NSValueTransformer*)databaseValueTransformerForKey:(NSString*)key;

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
