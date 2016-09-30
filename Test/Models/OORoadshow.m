//
//  OORoadshow.m
//  OOModel
//

#import "OORoadshow.h"
@implementation OORoadshow

OO_MODEL_IMPLEMENTION_JSON_KEYS(OO_PAIR(rid,id),
                                OO_PAIR(creator,extra.creator),
                                OO_PAIR(title,title),
                                OO_PAIR(membercount,membercount)
                                )

OO_MODEL_IMPLEMENTION_UNIQUE(rid)

OO_MODEL_IMPLEMENTION_DB_KEYS(rid,title,creator,membercount)

+ (OODbColumnType)oo_dbColumnTypeForPropertyKey:(NSString *)propertyKey{
    if ([propertyKey isEqualToString:@"creator"]) {
        return OODbColumnTypeInteger;
    }
    return OODbColumnTypeUnknow;
}
//+ (NSValueTransformer*)oo_dbValueTransformerForPropertyKey:(NSString *)propertyKey{
//    if ([propertyKey isEqualToString:@"creator"]) {
//        return [OOValueTransformer transformerWithForwardBlock:^id(id value) {
//            return [OOUser oo_modelWithUniqueValue:value];
//        } reverseBlock:^id(OOUser * value) {
//            return @(value.uid);
//        }];
//    }
//    return nil;
//}

@end
