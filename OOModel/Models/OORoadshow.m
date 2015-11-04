//
//  OORoadshow.m
//  OOModel
//

#import "OORoadshow.h"
@interface OORoadshow() <OOManagedObject,OOJsonSerializing,OODatabaseSerializing>

@end
@implementation OORoadshow

#pragma mark --
#pragma mark -- OODatabaseSerializing

+ (NSDictionary*)jsonKeyPathsByPropertyKeys{
    return [[NSDictionary oo_dictionaryByMappingKeypathsForPropertyWithClass:self]oo_dictionaryByAddingEntriesFromDictionary:@{@"rid":@"id",@"creator":@"extra.creator"}];
}

+ (NSValueTransformer*)jsonValueTransformerForKey:(NSString*)key{
    if ([key isEqualToString:@"rid"]||[key isEqualToString:@"membercount"]) {
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
    }else if ([key isEqualToString:@"creator"]){
        return [OOValueTransformer transformerWithForwardBlock:^id(NSDictionary * value) {
            if ([value isKindOfClass:NSDictionary.class]) {
                return [OOUser oo_modelWithJsonDictionary:value];
            }
            return nil;
        } reverseBlock:^id(OOUser * value) {
            if ([value isKindOfClass:OOUser.class]) {
                return [value jsonDictionary];
            }
            return nil;
        }];
    }
    return nil;
}

#pragma mark --
#pragma mark -- OODatabaseSerializing

+ (NSDictionary*)databaseColumnsByPropertyKeys{
    return [NSDictionary oo_dictionaryByMappingKeypathsForPropertyWithClass:self];
}

+ (NSDictionary*)databaseColumnTypesByPropertyKeys{
    return @{
             @"rid":@(OODatabaseColumnTypeInteger),
             @"title":@(OODatabaseColumnTypeText),
             @"membercount":@(OODatabaseColumnTypeInteger),
             @"creator":@(OODatabaseColumnTypeInteger)
             };
}

+ (NSValueTransformer*)databaseValueTransformerForKey:(NSString *)key{
    if ([key isEqualToString:@"creator"]) {
        return [OOValueTransformer transformerWithForwardBlock:^id(NSNumber * value) {
            if ([value isKindOfClass:NSNumber.class]) {
                id databasePrimaryValue=value;
                NSString *primaryKey=[OOUser databasePrimaryKey];
                NSString *databasePrimaryKey=[OOUser databaseColumnForPropertyKey:primaryKey];
                if (databasePrimaryValue) {
                    return [OOUser oo_modelWithSql:[NSString stringWithFormat:@"%@=?",databasePrimaryKey] arguments:@[databasePrimaryValue]];
                }
            }
            return nil;
        } reverseBlock:^id(OOUser * value) {
            if ([value isKindOfClass:OOUser.class]) {
                return @(value.uid);
            }
            return nil;
        }];
    }
    return nil;
}

+ (NSString*)databaseTableName{
    return @"OORoadshow";
}

+ (NSString*)databasePrimaryKey{
    return @"rid";
}

#pragma mark --
#pragma mark -- OOManagerSerializing

+ (NSString*)managedPrimaryKey{
    return [self databasePrimaryKey];
}

+ (NSString*)managedMapTableName{
    return [self databaseTableName];
}


@end
