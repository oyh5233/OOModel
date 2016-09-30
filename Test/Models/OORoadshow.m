//
//  OORoadshow.m
//  OOModel
//

#import "OORoadshow.h"
@implementation OORoadshow

//+ (NSDictionary*)jsonKeyPathsByPropertyKeys{
//    NSDictionary * dictionary=@{
//                                @"rid":@"id",
//                                @"creator":@"extra.creator"
//                                };
//    dictionary= [[NSDictionary oo_dictionaryByMappingKeyPathsForPropertiesWithClass:self] oo_dictionaryByAddingEntriesFromDictionary:dictionary];
//    return dictionary;
//}

OO_MODEL_IMPLEMENTION_JSON_KEYS(OO_PAIR(rid,id),
                                OO_PAIR(creator,extra.creator),
                                OO_PAIR(title,title),
                                OO_PAIR(membercount,membercount)
                                )

OO_MODEL_IMPLEMENTION_UNIQUE(rid)

OO_MODEL_IMPLEMENTION_DB_KEYS(rid,title,creator,membercount)

+ (NSValueTransformer*)oo_dbValueTransformerForPropertyKey:(NSString *)propertyKey{
    if ([propertyKey isEqualToString:@"creator"]) {
        return [OOValueTransformer transformerWithForwardBlock:^id(id value) {
            return [OOUser oo_modelWithUniqueValue:value];
        } reverseBlock:^id(OOUser * value) {
            return @(value.uid);
        }];
    }
    return nil;
}

@end
