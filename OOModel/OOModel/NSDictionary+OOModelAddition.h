//
//  NSDictionary+OOModelAddition.h
//  OOModel
//

#import <Foundation/Foundation.h>

@interface NSDictionary (OOModelAddition)

+ (NSDictionary*)oo_dictionaryByMappingKeypathsForPropertyWithClass:(Class)modelClass;

-(NSDictionary*)oo_dictionaryByAddingEntriesFromDictionary:(NSDictionary*)dictionary;

- (NSDictionary*)oo_dictionaryByRemoveKeys:(NSArray*)keys;

@end
