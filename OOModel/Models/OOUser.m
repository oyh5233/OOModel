//
//  OOUser.m
//  OOModel
//

#import "OOUser.h"

@implementation OOUser

+ (NSDictionary*)jsonKeyPathsByPropertyKeys{
    NSDictionary * dictionary=@{
                                @"uid":@"id",
                                };
    dictionary= [[NSDictionary oo_dictionaryByMappingKeyPathsForPropertiesWithClass:self] oo_dictionaryByAddingEntriesFromDictionary:dictionary];
    return dictionary;
}

+ (NSArray*)dbColumnsInPropertyKeys{
    return [[self jsonKeyPathsByPropertyKeys] allKeys];
}

+ (NSString *)uniquePropertyKey{
    return @"uid";
}
@end
