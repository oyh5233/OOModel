//
//  OOModel+OOJsonSerializing.h
//  OOModel
//

#import "OOModel.h"
@protocol OOJsonSerializing <NSObject>

+ (NSDictionary*)jsonKeyPathsByPropertyKey;

@optional

+ (NSValueTransformer*)jsonValueTransformerForKey:(NSString*)key;

@end

@interface OOModel (OOJsonSerializing)

+ (instancetype)modelWithJsonDictionary:(NSDictionary*)jsonDictionary;

- (instancetype)initWithJsonDictionary:(NSDictionary*)jsonDictionary;

- (BOOL)mergeWithJsonDictionary:(NSDictionary*)jsonDictionary;

- (NSDictionary*)jsonDictionary;

@end
