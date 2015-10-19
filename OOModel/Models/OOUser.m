//
//  OOUser.m
//  OOModel
//

#import "OOUser.h"

@implementation OOUser

#pragma mark --
#pragma mark -- OOJsonSerializing

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

#pragma mark --
#pragma mark -- OODatabaseSerializing

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

+ (NSString*)databaseTableName{
    return @"OOUser";
}

+ (NSString*)databasePrimaryKey{
    return @"uid";
}

#pragma mark --
#pragma mark -- OODatabaseSerializing

+ (NSString*)managerMapTableName{
    return [self databaseTableName];
}

+ (NSString*)managerPrimaryKey{
    return [self databasePrimaryKey];
}
@end
