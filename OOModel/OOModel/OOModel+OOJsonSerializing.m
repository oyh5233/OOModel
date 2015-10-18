//
//  OOModel+OOJsonSerializing.m
//  OOModel
//

#import "OOModel+OOJsonSerializing.h"
#import "objc/runtime.h"

@implementation OOModel (OOJsonSerializing)

#pragma mark --
#pragma mark -- init

+ (instancetype)modelWithJsonDictionary:(NSDictionary*)jsonDictionary{
    return [[self alloc]initWithJsonDictionary:jsonDictionary];
}

- (instancetype)initWithJsonDictionary:(NSDictionary*)jsonDictionary{
    self=[self init];
    if (self) {
        [self mergeWithJsonDictionary:jsonDictionary];
    }
    return self;
}

#pragma mark --
#pragma mark -- merge

- (BOOL)mergeWithJsonDictionary:(NSDictionary *)jsonDictionary{
   return [self mergeWithDictionary:[self.class _dictionaryWithJsonDictionary:jsonDictionary]];
}

#pragma mark --
#pragma mark -- getter

- (NSDictionary*)jsonDictionary{
    NSMutableDictionary *jsonDictionary=[NSMutableDictionary dictionary];
    [[self dictionary] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        @autoreleasepool {
            key=[self.class _keyPathsByPropertyKey][key];
            if (key&&![obj isKindOfClass:NSNull.class]) {
                NSValueTransformer *valueTransformer=[self.class _jsonValueTransformerForKey:key];
                if (valueTransformer) {
                    obj=[valueTransformer reverseTransformedValue:obj];
                }
                if (obj) {
                    [jsonDictionary setObject:obj forKey:key];
                }
            }
        }
    }];
    return jsonDictionary;
}

+ (NSDictionary*)_dictionaryWithJsonDictionary:(NSDictionary*)jsonDictionary{
    if (![jsonDictionary isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
    [jsonDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        @autoreleasepool {
            key=[self.class _propertyKeysByKeyPath][key];
            if (key&&![obj isKindOfClass:NSNull.class]) {
                NSValueTransformer *valueTransformer=[self.class _jsonValueTransformerForKey:key];
                if (valueTransformer) {
                    obj=[valueTransformer transformedValue:obj];
                }
                if (obj) {
                    [dictionary setObject:obj forKey:key];
                }
            }
        }
    }];
    return dictionary;
}

+ (NSDictionary*)_keyPathsByPropertyKey{
    NSDictionary * keyPathsByPropertyKey=objc_getAssociatedObject(self, @selector(_keyPathsByPropertyKey));
    if (!keyPathsByPropertyKey) {
        keyPathsByPropertyKey=[self.class jsonKeyPathsByPropertyKey];
        NSParameterAssert([keyPathsByPropertyKey isKindOfClass:NSDictionary.class]);
        [keyPathsByPropertyKey enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSParameterAssert([key isKindOfClass:NSString.class]);
            NSParameterAssert([obj isKindOfClass:NSString.class]);
        }];
        objc_setAssociatedObject(self, @selector(_keyPathsByPropertyKey), keyPathsByPropertyKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return keyPathsByPropertyKey;
}

+ (NSDictionary*)_propertyKeysByKeyPath{
    NSMutableDictionary * propertyKeysByKeyPath=objc_getAssociatedObject(self, @selector(_propertyKeysByKeyPath));
    if (!propertyKeysByKeyPath) {
        propertyKeysByKeyPath=[NSMutableDictionary dictionary];
        NSDictionary *  keyPathsByPropertyKey=[self.class jsonKeyPathsByPropertyKey];
        [keyPathsByPropertyKey enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [propertyKeysByKeyPath setObject:key forKey:obj];
        }];
        objc_setAssociatedObject(self, @selector(_propertyKeysByKeyPath), propertyKeysByKeyPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return propertyKeysByKeyPath;
}

+ (NSValueTransformer*)_jsonValueTransformerForKey:(NSString*)key{
    if ([self.class respondsToSelector:@selector(jsonValueTransformerForKey:)]) {
        return [self.class jsonValueTransformerForKey:key];
    }
    return nil;
}

@end
