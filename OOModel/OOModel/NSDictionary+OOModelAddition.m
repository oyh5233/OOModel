//
//  NSDictionary+OOModelAddition.m
//  OOModel
//

#import "NSDictionary+OOModelAddition.h"
#import "OOModel.h"
@implementation NSDictionary (OOModelAddition)

+ (NSDictionary*)oo_dictionaryByMappingKeypathsForPropertyWithClass:(Class)modelClass{
    NSParameterAssert([modelClass isSubclassOfClass:[OOModel class]]);
    NSArray *propertyKeys = [modelClass propertyKeys];
    return [NSDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
}

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
