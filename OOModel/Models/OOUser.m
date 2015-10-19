//
//  OOUser.m
//  OOModel
//

#import "OOUser.h"

@implementation OOUser

+ (NSDictionary*)jsonKeyPathsByPropertyKey{
    return [[NSDictionary oo_dictionaryByMappingKeypathsForPropertyWithClass:self]oo_dictionaryByAddingEntriesFromDictionary:@{@"uid":@"id"}];
}

+ (NSValueTransformer*)jsonValueTransformerForKey:(NSString*)key{
    if ([key isEqualToString:@"uid"]||[key isEqualToString:@"sex"]||[key isEqualToString:@"age"]) {
        return [OOValueTransformer transformerWithForwardBlock:^id(NSString * value) {
            if ([value isKindOfClass:NSString.class]) {
                return @(value.integerValue);
            }
            return nil;
        } reverseBlock:^id(NSNumber * value) {
            if ([value isKindOfClass:NSNumber.class]) {
                return [NSString stringWithFormat:@"%@",value];
            }
            return nil;
        }];
    }
    return nil;
}

+ (NSDictionary*)databaseColumnsByPropertyKey{
    return [[NSDictionary oo_dictionaryByMappingKeypathsForPropertyWithClass:self]oo_dictionaryByAddingEntriesFromDictionary:@{@"uid":@"o_uid",@"name":@"o_name",@"sex":@"o_sex",@"age":@"o_age"}];
}

+ (NSDictionary*)databaseColumnTypesByPropertyKey{
    return @{
             @"uid":@(OODatabaseColumnTypeInteger),
             @"name":@(OODatabaseColumnTypeText),
             @"sex":@(OODatabaseColumnTypeInteger)
             };
}

+ (NSValueTransformer*)databaseValueTransformerForKey:(NSString *)key{
    return nil;
}

+ (NSString*)databaseTableName{
    return @"OOUser";
}

+ (NSString*)databasePrimaryKey{
    return @"uid";
}

+ (NSString*)managerMapTableName{
    return @"OOUser";
}

+ (NSString*)managerPrimaryKey{
    return @"uid";
}
@end
