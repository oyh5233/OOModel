//
//  OORoadshow.m
//  OOModel
//

#import "OORoadshow.h"
@implementation OORoadshow

+ (NSDictionary*)jsonKeyPathsByPropertyKeys{
    NSDictionary * dictionary=@{
                                @"rid":@"id",
                                @"creator":@"extra.creator"
                                };
    dictionary= [[NSDictionary oo_dictionaryByMappingKeyPathsForPropertiesWithClass:self] oo_dictionaryByAddingEntriesFromDictionary:dictionary];
    return dictionary;
}

+ (NSArray*)dbColumnsInPropertyKeys{
    return [[self jsonKeyPathsByPropertyKeys] allKeys];
}

+ (NSValueTransformer*)dbValueTransformerForPropertyKey:(NSString *)propertyKey{
    if ([propertyKey isEqualToString:@"creator"]) {
        return [OOValueTransformer transformerWithForwardBlock:^id(id value) {
            return [OOUser oo_modelWithUniqueValue:value];
        } reverseBlock:^id(OOUser * value) {
            return @(value.uid);
        }];
    }
    return nil;
}
+ (NSString *)uniquePropertyKey{
    return @"rid";
}


@end
