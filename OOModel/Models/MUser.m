//
//  MUser.m
//  OOModel
//
//  Created by oo on 15/9/21.
//  Copyright © 2015年 comein. All rights reserved.
//

#import "MUser.h"

@implementation MUser
+ (instancetype)userWithUid:(NSNumber *)uid{
    if ([uid isKindOfClass:[NSNumber class]]) {
        return [[self class]oo_modelWithSql:@"uid=?",uid];
    }
    return nil;
}
+ (NSArray*)usersWithUids:(NSArray *)uids{
    if (uids.count>0) {
        NSMutableString *sql=[NSMutableString string];
        NSString *or=@" or ";
        for(NSNumber * uid in uids){
            if ([uid isKindOfClass:[NSNumber class]]) {
                [sql appendFormat:@"uid=%@%@",uid,or];
            }
        }
        [sql deleteCharactersInRange:NSMakeRange(sql.length-or.length, or.length)];
        if (sql.length>0) {
           return [[self class]oo_modelsWithSql:sql];
        }
    }
    return [NSMutableArray array];
}

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
               @"uid":@(OO_DatabaseColumnTypeInteger),
               @"nickName":@(OO_DatabaseColumnTypeText)
               };
    }
    return dict;
}

+ (nullable NSString*)oo_databasePrimaryKey{
    return @"uid";
}
+ (NSDictionary*)JSONKeyPathsByPropertyKey{
    return [NSDictionary mtl_identityPropertyMapWithModel:self];
}
@end
