//
//  NSDictionary+OOAdditions.m
//  OOModel
//

#import "NSDictionary+OOAdditions.h"
#import "NSObject+OOModel.h"

@implementation NSDictionary (OOAdditions)

+ (NSDictionary*)oo_dictionaryByMappingKeyPathsForPropertiesWithClass:(Class)modelClass{
    NSArray *propertyKeys = [modelClass oo_classInfo].propertyKeys;
    return [NSDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
}
//
//+ (NSDictionary*)oo_dictionaryByMappingKeyPathsForPropertiesWithClass:(Class)modelClass addPrefix:(NSString*)prefix{
//    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
//    NSArray *propertyKeys = [modelClass oo_classInfo].propertyKeys;
//    for (NSString * propertyKey in propertyKeys){
//        [dictionary setObject:[NSString stringWithFormat:@"%@_%@",prefix,propertyKey] forKey:propertyKey];
//    }
//    return dictionary;
//}

-(NSDictionary*)oo_dictionaryByAddingEntriesFromDictionary:(NSDictionary*)dictionary{
    NSMutableDictionary * mDictionary=[self mutableCopy];
    [mDictionary addEntriesFromDictionary:dictionary];
    return mDictionary;
}

- (NSDictionary*)oo_dictionaryByRemoveKeys:(NSArray*)keys{
    NSMutableDictionary * mDictionary=[self mutableCopy];
    [keys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mDictionary removeObjectForKey:obj];
    }];
    return mDictionary;
}

@end
