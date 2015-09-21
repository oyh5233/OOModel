//
//  Group.m
//  OOModel
//
//  Created by oo on 15/9/21.
//  Copyright © 2015年 comein. All rights reserved.
//

#import "MGroup.h"

@implementation MGroup
+ (nonnull NSString*)oo_databaseTableName{
    static NSString *tableName=nil;
    if (!tableName) {
        tableName=NSStringFromClass([self class]);
    }
    return tableName;
}

+ (nonnull NSDictionary*)oo_databaseColumnTypeForKeys{
    static NSDictionary *dict=nil;
    if (!dict) {
        dict=@{
               @"gid":@(OO_DatabaseColumnTypeInteger),
               @"title":@(OO_DatabaseColumnTypeText),
               @"notice":@(OO_DatabaseColumnTypeText),
               @"creator":@(OO_DatabaseColumnTypeInteger),
               @"members":@(OO_DatabaseColumnTypeText)
               };
    }
    return dict;
}
+ (nullable NSString*)oo_databasePrimaryKey{
    return @"gid";
}
+ (nullable NSValueTransformer* )oo_databaseTransformerForKey:(nonnull NSString*)key{
    if ([key isEqualToString:@"creator"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(User * value, BOOL *success, NSError *__autoreleasing *error) {
            return @(value.uid);
        } reverseBlock:^id(NSNumber * value, BOOL *success, NSError *__autoreleasing *error) {
            return [User oo_modelsWithSql:@"uid=?",value];
        }];
    }else if ([key isEqualToString:@"members"]){
        return [MTLValueTransformer transformerUsingForwardBlock:^id(NSArray *value, BOOL *success, NSError *__autoreleasing *error) {
            NSMutableArray *uids=[NSMutableArray array];
            [value enumerateObjectsUsingBlock:^(User * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSInteger uid=obj.uid;
                if (uid>0) {
                    [uids addObject:@(uid)];
                }
            }];
            return uids.count>0?[[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:uids options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]:nil;
        } reverseBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
            NSArray * uids=[NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
            return [User usersWithUids:uids];
        }];
    }
    return nil;
}
+ (NSValueTransformer*)JSONTransformerForKey:(NSString *)key{
    if ([key isEqualToString:@"creator"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(NSDictionary *value, BOOL *success, NSError *__autoreleasing *error) {
            return [User oo_modelWithDictionary:value];
        } reverseBlock:^id(User *value, BOOL *success, NSError *__autoreleasing *error) {
            return [value dictionaryValue];
        }];
    }else if ([key isEqualToString:@"members"]){
        return [MTLValueTransformer transformerUsingForwardBlock:^id(NSArray *value, BOOL *success, NSError *__autoreleasing *error) {
            return [User oo_modelsWithDictionaries:value];
        } reverseBlock:^id(NSArray *value, BOOL *success, NSError *__autoreleasing *error) {
            NSMutableArray * dictionaries=[NSMutableArray array];
            [value enumerateObjectsUsingBlock:^(User * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [dictionaries addObject:[obj dictionaryValue]];
            }];
            return dictionaries;
        }];
    }
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        return value;
    }];
}
+ (NSDictionary*)JSONKeyPathsByPropertyKey{
    return [NSDictionary mtl_identityPropertyMapWithModel:self];
}
@end
