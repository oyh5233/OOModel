//
//  NSObject+OOModel.h
//  OOModel
//

#import <Foundation/Foundation.h>
#import "OOModelInfo.h"

extern const NSString * oo_compaction_prefix;
/**
 *  compact property key to column.
 *  e.g.
 *
 *  NSArray * models = [oo_modelsWithAfterWhereSql:[NSString stringWithFormat:@"%@ like ?",OOCOMPACT(@"keyword")] arguments:@[@"world"]];
 */
#define OOCOMPACT(tableorcolumn) [NSString stringWithFormat:@"%@%@",oo_compaction_prefix,tableorcolumn]

@protocol OOUniqueModel<NSObject>
/**
 *  this value is used by maptable and db.
 *
 *  @return unique value.
 */
+ (NSString*)uniquePropertyKey;

@end

@protocol OOJsonModel <NSObject>
/**
 *  mapping property key to json keyPath.
 *
 *  @return a mapping dictionary.
 */
+ (NSDictionary*)jsonKeyPathsByPropertyKeys;

@optional
/**
 *  if OOModel do not support this property,you should implementation this method.
 *
 *  @param propertyKey target property key
 *
 *  @return value trasformer.
 */
+ (NSValueTransformer*)jsonValueTransformerForPropertyKey:(NSString*)propertyKey;

@end

@protocol OODbModel <NSObject>
/**
 *  which property should be cached to db;
 *
 *  @return property keys array.
 */
+ (NSArray*)dbColumnsInPropertyKeys;

@optional
/**
 *  if OOModel do not support this property,you should implementation this method.
 *
 *  @param propertyKey target property key.
 *
 *  @return value trasformer.
 */
+ (NSValueTransformer*)dbValueTransformerForPropertyKey:(NSString*)propertyKey;
/**
 *  if OOmodel do not recognize this property,you should implementation this method.
 *
 *  @param propertyKey target property key.
 *
 *  @return column type.
 */
+ (OODbColumnType)dbColumnTypeForPropertyKey:(NSString*)propertyKey;

/**
 *  which property key should be indexed in db.
 *
 *  @return array of indexed property key.
 */
+ (NSArray*)dbIndexesInPropertyKeys;

@end

@interface NSObject (OOModel)

@property (nonatomic,copy,readonly) NSDictionary *oo_jsonDictionary;

@property (nonatomic,copy,readonly) NSString     *oo_jsonString;

@property (nonatomic,assign,readonly) bool       oo_isReplaced;

+ (NSArray*)oo_modelsWithJsonDictionaries:(NSArray*)jsonDictionaries;
/**
 *  model from json.
 *
 *  @param  dictionary or json string.
 *
 *  @return instance
 */
+ (instancetype)oo_modelWithJson:(id)json;
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
 *  NSArray * models = [oo_modelsWithAfterWhereSql:[NSString stringWithFormat:@"%@ like ?",OOCOMPACT(@"keyword")] arguments:@[@"world"]];
 */
+ (NSArray *)oo_modelsWithAfterWhereSql:(NSString*)afterWhereSql arguments:(NSArray*)arguments;
/**
 *  merge model with json.if model conforms to OOUniqueModel,but json has a different unique value,it will occur a error.
 *
 *  @param json 
 */
- (void)oo_mergeWithJson:(id)json;
/**
 *  if model class conforms to OODbModel,should open a db at first.All models use the same db.
 *
 *  @param file db file path.
 *
 *  @return result
 */
+ (void)oo_deleteModelsBeforeDate:(NSDate*)date;
/**
 *
 *
 *  @return class info of this class.
 */
+ (OOClassInfo*)oo_classInfo;

- (void)oo_modelEncode:(NSCoder *)aCoder;

- (id)oo_modelDecode:(NSCoder *)aDecoder;
@end
