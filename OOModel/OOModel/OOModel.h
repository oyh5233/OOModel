//
//  OOModel.h
//  OOModel
//

#import <Foundation/Foundation.h>
#import "NSDictionary+OOModelAddition.h"
#import "OOValueTransformer.h"

#define OOModelLog(fmt, ...) NSLog((@"[Function %s][Line %d] " fmt),__FUNCTION__,__LINE__, ##__VA_ARGS__)

@interface OOModel : NSObject

+ (instancetype)modelWithDictionary:(NSDictionary*)dictionary;

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

- (BOOL)mergeWithDictionary:(NSDictionary*)dictionary;

- (NSDictionary*)dictionary;

+ (NSArray *)propertyKeys;

@end
