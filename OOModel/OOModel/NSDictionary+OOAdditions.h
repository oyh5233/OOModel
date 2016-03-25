//
//  NSDictionary+OOAdditions.h
//  OOModel
//

#import <Foundation/Foundation.h>

@interface NSDictionary (OOAdditions)

+ (NSDictionary*)oo_dictionaryByMappingKeyPathsForPropertiesWithClass:(Class)modelClass;

-(NSDictionary*)oo_dictionaryByAddingEntriesFromDictionary:(NSDictionary*)dictionary;

- (NSDictionary*)oo_dictionaryByRemoveKeys:(NSArray*)keys;

@end
