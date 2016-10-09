//
//  NSObject+OOModel.h
//  OOModel
//

#import "OOModelInfo.h"
#import <Foundation/Foundation.h>

extern const NSString *oo_compaction_prefix;
/**
 *  compact property key to column.
 *  e.g.
 *
 *  NSArray * models = [oo_modelsWithAfterWhereSql:[NSString stringWithFormat:@"%@ like ?",OOCOMPACT(@"keyword")] arguments:@[@"world"]];
 */

@protocol OOUniqueModel <NSObject>
/**
 *  this value is used by maptable and db.
 *
 *  @return unique value.
 */
+ (NSString *)oo_uniquePropertyKey;

@end

@protocol OOJsonModel <NSObject>
/**
 *  mapping property key to json keyPath.
 *
 *  @return a mapping dictionary.
 */
+ (NSDictionary *)oo_jsonKeyPathsByPropertyKeys;

@optional
/**
 *  if OOModel do not support this property,you should implementation this method.
 *
 *  @param propertyKey target property key
 *
 *  @return value trasformer.
 */
+ (NSValueTransformer *)oo_jsonValueTransformerForPropertyKey:(NSString *)propertyKey;

@end

@protocol OODbModel <NSObject>
/**
 *  which property should be cached to db;
 *
 *  @return property keys array.
 */
+ (NSArray *)oo_dbColumnNamesInPropertyKeys;

@optional
/**
 *  if OOModel do not support this property,you should implementation this method.
 *
 *  @param propertyKey target property key.
 *
 *  @return value trasformer.
 */
+ (NSValueTransformer *)oo_dbValueTransformerForPropertyKey:(NSString *)propertyKey;
/**
 *  if OOmodel do not recognize this property,you should implementation this method.
 *
 *  @param propertyKey target property key.
 *
 *  @return column type.
 */
+ (OODbColumnType)oo_dbColumnTypeForPropertyKey:(NSString *)propertyKey;

/**
 *  which property key should be indexed in db.
 *
 *  @return array of indexed property key.
 */
+ (NSArray *)oo_dbIndexesInPropertyKeys;

@end

@interface NSObject (OOModel)

@property(nonatomic, strong, readonly) NSDictionary *oo_dictionary;

@property(nonatomic, strong, readonly) NSDictionary *oo_jsonDictionary;

@property(nonatomic, copy, readonly) NSString *oo_jsonString;

@property(nonatomic, assign, readonly) bool oo_isReplaced;

+ (NSArray *)oo_modelsWithJsonDictionaries:(NSArray *)jsonDictionaries;

+ (id)oo_modelWithJsonDictionary:(NSDictionary *)jsonDictionary;
/**
 *  if model's class conform to protocol OOUniqueModel,
 *
 *  @param value unique value
 *
 *  @return instance
 */
+ (instancetype)oo_modelWithUniqueValue:(id)uniqueValue;
/*
 *  e.g.
 *
 *  NSArray * models = [class oo_modelsWithAfterWhereSql:[NSString stringWithFormat:@"keyword like ?"] arguments:@[@"world"]];
 */
+ (NSArray *)oo_modelsWithAfterWhereSql:(NSString *)afterWhereSql arguments:(NSArray *)arguments;
/**
 *  merge model with json.if model conforms to OOUniqueModel,but json has a different unique value,it will occur a error.
 *
 *  @param json 
 */
+ (void)oo_save:(NSArray *)models;

- (void)oo_save;

- (void)oo_mergeWithJsonDictionary:(NSDictionary *)dictionary;

/**
 *  if model class conforms to OODbModel,should open a db at first.All models use the same db.
 *
 *  @param file db file path.
 *
 *  @return result
 */
+ (void)oo_deleteModelsBeforeDate:(NSDate *)date;
/**
 *  set global database cache for instance.
 *
 *  @param db database for disk cache.
 */
+ (void)oo_setGlobalDb:(OODb *)db;

+ (OOClassInfo *)oo_classInfo;

@end
