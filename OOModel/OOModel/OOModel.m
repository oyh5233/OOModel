//
//  OOModel.m
//  OOModel
//

#import "OOModel.h"
#import "objc/runtime.h"

static const void *  OOModelMainQueueKey = &OOModelMainQueueKey;

@implementation OOModel

#pragma mark --
#pragma mark -- init

+ (instancetype)modelWithDictionary:(NSDictionary*)dictionary{
    return [[self alloc]initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary{
    self=[self init];
    if (self) {
        if (![self mergeWithDictionary:dictionary]) {
            self=nil;
        }
    }
    return self;
}

#pragma mark --
#pragma mark -- merge

- (BOOL)mergeWithDictionary:(NSDictionary*)dictionary{
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:NSNull.class]) {
            __autoreleasing id validateObj=obj;
            NSError *error=nil;
            if ([self validateValue:&validateObj forKey:key error:&error]) {
                [self setValue:validateObj forKey:key];
            }else{
                OOModelLog(@"%@",error);
            }
        }
    }];
    return YES;
}

#pragma mark --
#pragma mark -- override
+ (void)load{
    [super load];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_set_specific(dispatch_get_main_queue(), OOModelMainQueueKey, (__bridge void *)self, NULL);
    });
}
- (void)setValue:(id)value forKey:(NSString *)key{
    if (dispatch_get_specific(OOModelMainQueueKey)) {
        [super setValue:value forKey:key];
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [super setValue:value forKey:key];
        });
    }
}

#pragma mark --
#pragma mark -- enumerate keys

+ (void)_enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
    Class class = self;
    BOOL stop = NO;
    while (!stop && ![class isEqual:OOModel.class]) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(class, &count);
        class = class.superclass;
        if (properties == NULL) {
            continue;
        }
        for (unsigned i = 0; i < count; i++) {
            objc_property_t property=properties[i];
            block(property, &stop);
            if (stop) {
                free(properties);
                break;
            }
        }
        free(properties);
    }
}

#pragma mark --
#pragma mark -- getter

+ (NSArray *)propertyKeys {
    NSMutableArray *cachedKeys = objc_getAssociatedObject(self, @selector(propertyKeys));
    if (!cachedKeys) {
        cachedKeys = [NSMutableArray array];
        [self _enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
            @autoreleasepool {
                NSString *key = @(property_getName(property));
                NSString * propertyAttributesString=[[NSString alloc] initWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
                NSArray *propertyAttributes=[propertyAttributesString componentsSeparatedByString:@","];
                __block BOOL filtered=NO;
                [propertyAttributes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isEqualToString:@"R"]) {
                        filtered=YES;
                        *stop=YES;
                    }
                }];
                if (!filtered) {
                    [cachedKeys addObject:key];
                }
            }
        }];
        objc_setAssociatedObject(self, @selector(propertyKeys), cachedKeys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cachedKeys;
}

- (NSDictionary*)dictionary{
    return [self dictionaryWithValuesForKeys:[self.class propertyKeys]];
}

- (NSString*)description{
    return [[self dictionary] description];
}

@end
