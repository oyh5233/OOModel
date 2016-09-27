//
//  NSObject+OOModel.m
//  OOModel
//

#import "NSObject+OOModel.h"
#import <objc/message.h>
#import "OOMapTable.h"
const NSString * oo_compaction_prefix    = @"oo_";
static NSString * oo_latest_used_timestamp = @"oo_latest_used_timestamp";
static OODb *oo_global_db=nil;
static CFMutableDictionaryRef oo_class_info_root=NULL;

typedef struct {
    
    void * model;
    void * storage;
    
}OOModelContext;

typedef struct {
    void * model;
    void * sql;
    void * arguments;
    void * uniqueValue;
}OOModelDbUpdateContext;

typedef struct {
    void * model;
    void * sql1;
    void * sql2;
    void * arguments;
}OOModelDbInsertContext;

typedef struct {
    void * sql;
    void * propertyInfos;
}OOModelReplaceContext;

inline static NSString* oo_databaseColumnTypeWithType(OODbColumnType type) {
    NSString *dbColumnType=nil;
    switch (type) {
        case OODbColumnTypeText:
            dbColumnType=@"text";
            break;
        case OODbColumnTypeInteger:
            dbColumnType=@"integer";
            break;
        case OODbColumnTypeReal:
            dbColumnType=@"real";
            break;
        case OODbColumnTypeBlob:
            dbColumnType=@"blob";
            break;
        default:
            assert(NO);
            break;
    }
    return dbColumnType;
}

bool oo_set_object_for_property(__unsafe_unretained id model,__unsafe_unretained id object,__unsafe_unretained OOPropertyInfo *propertyInfo) {
    OOEncodingType encodingType=propertyInfo.encodingType;
    SEL setter=propertyInfo.setter;
    if (encodingType&OOEncodingTypeObject) {
        if([object isKindOfClass:propertyInfo.propertyCls]){
            ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, object);
            return YES;
        }
        if (object==nil||object==(id)kCFNull) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, nil);
            return YES;
        }
        switch (encodingType) {
            case OOEncodingTypeNSString:
                if ([object isKindOfClass:NSNumber.class]){
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter,[NSString stringWithFormat:@"%@",object]);
                    return YES;
                }else if([object isKindOfClass:NSData.class]){
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter,[object base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]);
                    return YES;
                }
            case OOEncodingTypeNSNumber:
                if ([object isKindOfClass:NSString.class]) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, @([object integerValue]));
                    return YES;
                }
            case OOEncodingTypeNSDate:
                if ([object respondsToSelector:@selector(doubleValue)]) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, [NSDate dateWithTimeIntervalSince1970:[object doubleValue]]);
                    return YES;
                }
            case OOEncodingTypeNSURL:
                if ([object isKindOfClass:NSString.class]) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, [NSURL URLWithString:object]);
                    return YES;
                }
            case OOEncodingTypeNSData:
                if ([object isKindOfClass:NSString.class]) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, [[NSData alloc]initWithBase64EncodedString:object options:NSDataBase64DecodingIgnoreUnknownCharacters]);
                    return YES;
                }
            default:
                break;
        }
        return NO;
    }else if (encodingType&OOEncodingTypeCType){
        if (object==nil||object==(id)kCFNull) {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)(model, setter, 0);
            return YES;
        }
        switch (encodingType) {
            case OOEncodingTypeBool:
                if ([object respondsToSelector:@selector(boolValue)]) {
                    ((void (*)(id, SEL, bool))(void *) objc_msgSend)(model, setter, [object boolValue]);
                    return YES;
                }
            case OOEncodingTypeInt8:
                if([object isKindOfClass:NSNumber.class]){
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, setter, [object charValue]);
                    return YES;
                }else if ([object respondsToSelector:@selector(intValue)]){
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, setter, (char)[object intValue]);
                    return YES;
                }
            case OOEncodingTypeUInt8:
                if([object isKindOfClass:NSNumber.class]){
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, setter, [object unsignedCharValue]);
                    return YES;
                }else if ([object respondsToSelector:@selector(intValue)]){
                    ((void (*)(id, SEL, UInt8))(void *) objc_msgSend)(model, setter, (UInt8)[object intValue]);
                    return YES;
                }
            case OOEncodingTypeInt16:
                if([object isKindOfClass:NSNumber.class]){
                    ((void (*)(id, SEL, short))(void *) objc_msgSend)(model, setter, [object shortValue]);
                    return YES;
                }else if ([object respondsToSelector:@selector(intValue)]){
                    ((void (*)(id, SEL, short))(void *) objc_msgSend)(model, setter, (short)[object intValue]);
                    return YES;
                }
            case OOEncodingTypeUInt16:
                if([object isKindOfClass:NSNumber.class]){
                    ((void (*)(id, SEL, UInt16))(void *) objc_msgSend)(model, setter, [object unsignedShortValue]);
                    return YES;
                }else if ([object respondsToSelector:@selector(intValue)]){
                    ((void (*)(id, SEL, UInt16))(void *) objc_msgSend)(model, setter, (UInt16)[object intValue]);
                    return YES;
                }
            case OOEncodingTypeInt32:
                if ([object respondsToSelector:@selector(intValue)]) {
                    ((void (*)(id, SEL, int))(void *) objc_msgSend)(model, setter, [object intValue]);
                    return YES;
                }
            case OOEncodingTypeUInt32:
                if([object isKindOfClass:NSNumber.class]){
                    ((void (*)(id, SEL, UInt32))(void *) objc_msgSend)(model, setter, [object unsignedIntValue]);
                    return YES;
                }else if ([object respondsToSelector:@selector(intValue)]){
                    ((void (*)(id, SEL, UInt32))(void *) objc_msgSend)(model, setter, (UInt32)[object intValue]);
                    return YES;
                }
            case OOEncodingTypeInt64:
                if ([object respondsToSelector:@selector(longLongValue)]){
                    ((void (*)(id, SEL, long long))(void *) objc_msgSend)(model, setter, (long long)[object longLongValue]);
                    return YES;
                }
            case OOEncodingTypeUInt64:
                if([object isKindOfClass:NSNumber.class]){
                    ((void (*)(id, SEL, UInt64))(void *) objc_msgSend)(model, setter, [object unsignedLongLongValue]);
                    return YES;
                }else if ([object respondsToSelector:@selector(longLongValue)]){
                    ((void (*)(id, SEL, UInt64))(void *) objc_msgSend)(model, setter, (UInt64)[object longLongValue]);
                    return YES;
                }
            case OOEncodingTypeFloat:
                if ([object respondsToSelector:@selector(floatValue)]) {
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, setter, [object floatValue]);
                    return YES;
                }
            case OOEncodingTypeDouble:
                if ([object respondsToSelector:@selector(doubleValue)]) {
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, setter, [object doubleValue]);
                    return YES;
                }
            default:
                break;
        }
        return NO;
    }
    return NO;
}

bool oo_get_object_for_property(__unsafe_unretained id model,id * outObject,__unsafe_unretained OOPropertyInfo *propertyInfo){
    OOEncodingType encodingType=propertyInfo.encodingType;
    SEL getter=propertyInfo.getter;
    if (encodingType&OOEncodingTypeObject) {
        void * voidValue=((void * (*)(id, SEL))(void *) objc_msgSend)(model, getter);
        if (!voidValue) {
            *outObject = nil;
            return YES;
        }
        if (encodingType==OOEncodingTypeNSString||encodingType==OOEncodingTypeNSNumber){
            *outObject= (__bridge id)voidValue;
            return YES;
        }else if (encodingType==OOEncodingTypeNSURL) {
            *outObject = [(__bridge id)voidValue absoluteString];
            return YES;
        }else if (encodingType==OOEncodingTypeNSDate) {
            *outObject= @([(__bridge id)voidValue timeIntervalSince1970]);
            return YES;
        }else if (encodingType==OOEncodingTypeNSData){
            *outObject=[(__bridge id)voidValue base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }
        return NO;
    }else if (encodingType&OOEncodingTypeCType){
        switch (encodingType) {
            case OOEncodingTypeBool:
                *outObject= @(((bool (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeInt8:
                *outObject= @(((char (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeUInt8:
                *outObject= @(((UInt8 (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeInt16:
                *outObject= @(((short (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeUInt16:
                *outObject= @(((UInt16 (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeInt32:
                *outObject= @(((int (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeUInt32:
                *outObject= @(((UInt32 (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeInt64:
                *outObject= @(((long long (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeUInt64:
                *outObject= @(((UInt64 (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeFloat:
                *outObject= @(((float (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeDouble:
                *outObject= @(((double (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            default:
                return NO;
        }
        return YES;
    }
    return NO;
}

static void oo_set_value_for_property_apply(const void *_value, void *_context){
    OOModelContext * context=_context;
    __unsafe_unretained NSDictionary *  jsonDictionary=(__bridge id)context->storage;
    __unsafe_unretained id model=(__bridge id)context->model;
    __unsafe_unretained OOPropertyInfo *propertyInfo=(__bridge id)_value;
    __unsafe_unretained id jsonKeyPath= propertyInfo.jsonKeyPath;
    id value=jsonDictionary;
    if ([jsonKeyPath isKindOfClass:NSString.class]) {
        value=jsonDictionary[jsonKeyPath];
    }else{
        NSInteger count=[jsonKeyPath count];
        NSInteger i=0;
        for(;i<count;i++){
            id nodeValue=value[jsonKeyPath[i]];
            if (nodeValue) {
                value=nodeValue;
            }else{
                break;
            }
        }
        if (i!=count) {
            value=nil;
        }
    }
    if (!value) {
        return;
    }
    if (propertyInfo.propertyType&OOPropertyTypeReadonly) {
        return;
    }
    __unsafe_unretained NSValueTransformer *valueTransformer=propertyInfo.jsonValueTransformer;
    if (valueTransformer) {
        value=[valueTransformer transformedValue:value];
    }
    if (propertyInfo.jsonForwards) {
        value=((id (*)(Class, SEL,id))(void *) objc_msgSend)(propertyInfo.propertyCls,propertyInfo.jsonForwards,value);
        if (!oo_set_object_for_property(model, value, propertyInfo)) {
            goto set_fail;
        }
    }else{
        if (!oo_set_object_for_property(model, value, propertyInfo)) {
            goto set_fail;
        }
    }
    return;
set_fail:
    [NSException raise:@"set fail" format:@"model_class:%@\nvalue_class:%@\nproperty:%@\nmethod:\"jsonValueTransformerForPropertyKey:\"",NSStringFromClass([model class]),NSStringFromClass([value class]),propertyInfo.propertyKey];
}

static void oo_get_value_for_property_apply(const void *_value, void * _context){
    OOModelContext * context=_context;
    __unsafe_unretained id model=(__bridge id)context->model;
    __unsafe_unretained OOPropertyInfo *propertyInfo=(__bridge id)_value;
    __unsafe_unretained NSArray * jsonKeyPath= propertyInfo.jsonKeyPath;
    __unsafe_unretained NSMutableDictionary *  jsonDictionary=(__bridge id)context->storage;
    id value=nil;
    if (!oo_get_object_for_property(model,&value, propertyInfo)) {
        value =[model valueForKey:propertyInfo.propertyKey];
        if (value) {
            if(propertyInfo.jsonBackwards){
                value=((id (*)(Class, SEL))(void *) objc_msgSend)(value,propertyInfo.jsonBackwards);
            }else{
                [NSException raise:@"get fail" format:@"model_class:%@\nvalue_class:%@\nproperty:%@\nmethod:\"jsonValueTransformerForPropertyKey:\"",NSStringFromClass([model class]),NSStringFromClass([value class]),propertyInfo.propertyKey];
            }
        }
    }
    __unsafe_unretained NSValueTransformer *valueTransformer=propertyInfo.jsonValueTransformer;
    if (valueTransformer) {
        value=[model valueForKey:propertyInfo.propertyKey];
        value=[valueTransformer reverseTransformedValue:value];
    }
    if (!value) {
        return;
    }
    NSMutableDictionary * parent=jsonDictionary;
    if ([jsonKeyPath isKindOfClass:NSString.class]) {
        parent[jsonKeyPath]=value;
    }else{
        NSInteger count=jsonKeyPath.count;
        int i=0;
        for(;i<count-1;i++){
            NSMutableDictionary *child=parent[jsonKeyPath[i]];
            if (!child) {
                child=[NSMutableDictionary dictionary];
                parent[jsonKeyPath[i]]=child;
                parent=child;
            }
        }
        parent[jsonKeyPath[i]]=value;
    }
}

static void oo_set_value_for_property_apply_db(const void *_value, void *_context){
    OOModelContext * context=_context;
    __unsafe_unretained NSDictionary *  dbDictionary=(__bridge id)context->storage;
    __unsafe_unretained id model=(__bridge id)context->model;
    __unsafe_unretained OOPropertyInfo *propertyInfo=(__bridge id)_value;
    id value=dbDictionary[propertyInfo.dbColumn];
    if (!value) {
        return;
    }
    if (propertyInfo.propertyType&OOPropertyTypeReadonly) {
        return;
    }
    __unsafe_unretained NSValueTransformer *valueTransformer=propertyInfo.dbValueTransformer;
    if (valueTransformer) {
        value=[valueTransformer transformedValue:value];
    }else if (propertyInfo.dbForwards) {
        value=((id (*)(Class, SEL,id))(void *) objc_msgSend)(propertyInfo.propertyCls,propertyInfo.dbForwards,value);
    }
    if (!oo_set_object_for_property(model, value, propertyInfo)) {
        goto set_fail;
    }
    return;
set_fail:
    [NSException raise:@"set fail" format:@"model_class:%@\nvalue_class:%@\nproperty:%@\nmethod:\"jsonValueTransformerForPropertyKey:\"",NSStringFromClass([model class]),NSStringFromClass([value class]),propertyInfo.propertyKey];
}

static void oo_db_update_apply(const void *_value,void *_context){
    OOModelDbUpdateContext *context=_context;
    __unsafe_unretained NSMutableString *sql=(__bridge NSMutableString *)context->sql;
    __unsafe_unretained NSMutableArray  *arguments=(__bridge NSMutableArray*)context->arguments;
    __unsafe_unretained id model=(__bridge id)context->model;
    __unsafe_unretained OOPropertyInfo * propertyInfo=(__bridge OOPropertyInfo*)_value;
    id value=nil;
    __unsafe_unretained NSValueTransformer *valueTransformer=propertyInfo.dbValueTransformer;
    if (valueTransformer) {
        value=[model valueForKey:propertyInfo.propertyKey];
        value=[valueTransformer reverseTransformedValue:value];
    }else{
        if (propertyInfo.encodingType==OOEncodingTypeNSData) {
            value=[model valueForKey:propertyInfo.propertyKey];
        }else{
            if (!oo_get_object_for_property(model,&value, propertyInfo)) {
                [NSException raise:@"get fail" format:@"model_class:%@\nvalue_class:%@\nproperty:%@\nmethod:\"dbValueTransformerForPropertyKey:\"",NSStringFromClass([model class]),NSStringFromClass([value class]),propertyInfo.propertyKey];
            }
        }
    }
    if (!value) {
        return;
    }
    [sql appendString:propertyInfo.dbColumn];
    [sql appendString:@"=?,"];
    [arguments addObject:value];
}

static void oo_db_insert_apply(const void *_value,void *_context){
    OOModelDbInsertContext *context=_context;
    __unsafe_unretained NSMutableString *sql1=(__bridge NSMutableString *)context->sql1;
    __unsafe_unretained NSMutableString *sql2=(__bridge NSMutableString *)context->sql2;
    __unsafe_unretained NSMutableArray  *arguments=(__bridge NSMutableArray*)context->arguments;
    __unsafe_unretained id model=(__bridge id)context->model;
    __unsafe_unretained OOPropertyInfo * propertyInfo=(__bridge OOPropertyInfo*)_value;
    id value=nil;
    __unsafe_unretained NSValueTransformer *valueTransformer=propertyInfo.dbValueTransformer;
    if (valueTransformer) {
        value=[model valueForKey:propertyInfo.propertyKey];
        value=[valueTransformer reverseTransformedValue:value];
    }else{
        if (propertyInfo.encodingType==OOEncodingTypeNSData) {
            value=[model valueForKey:propertyInfo.propertyKey];
        }else{
            if (!oo_get_object_for_property(model,&value, propertyInfo)) {
                [NSException raise:@"get fail" format:@"model_class:%@\nvalue_class:%@\nproperty:%@\nmethod:\"dbValueTransformerForPropertyKey:\"",NSStringFromClass([model class]),NSStringFromClass([value class]),propertyInfo.propertyKey];
            }
        }
    }
    if (!value) {
        return;
    }
    [sql1 appendString:propertyInfo.dbColumn];
    [sql1 appendString:@","];
    [sql2 appendString:@"?,"];
    [arguments addObject:value];
}

static void oo_encode_apply(const void *_propertyInfo, void *_context){
    OOModelContext * context=_context;
    __unsafe_unretained NSCoder *coder=(__bridge id)context->storage;
    __unsafe_unretained id model=(__bridge id)context->model;
    __unsafe_unretained OOPropertyInfo *propertyInfo=(__bridge id)_propertyInfo;
    id value;
    if(!oo_get_object_for_property(model, &value,propertyInfo)){
        value=[model valueForKey:propertyInfo.propertyKey];
    }
    if (value) {
        [coder encodeObject:value forKey:propertyInfo.propertyKey];
    }
}

static void oo_decode_apply(const void *_propertyInfo, void *_context){
    OOModelContext * context=_context;
    __unsafe_unretained NSCoder *coder=(__bridge id)context->storage;
    __unsafe_unretained id model=(__bridge id)context->model;
    __unsafe_unretained OOPropertyInfo *propertyInfo=(__bridge id)_propertyInfo;
    id value=[coder decodeObjectForKey:propertyInfo.propertyKey];
    if (value) {
        if (!oo_set_object_for_property(model, value, propertyInfo)) {
            [model setValue:value forKey:propertyInfo.propertyKey];
        }
    }
}

@implementation NSObject (OOModel)

+ (NSArray*)oo_modelsWithJsonDictionaries:(NSArray*)jsonDictionaries{
    OOClassInfo *classInfo=[self oo_classInfo];
    NSMutableArray *models=[NSMutableArray array];
    void(^block)(OOMapTable *mt,OODatabase *db,BOOL isInDbQueue)=^(OOMapTable *mt,OODatabase *db,BOOL isInDbQueue){
        for (int i=0;i<jsonDictionaries.count;i++){
            NSDictionary *jsonDictionary=jsonDictionaries[i];
            id model=[self oo_modelWithJsonDictionary:jsonDictionary classInfo:classInfo mt:mt db:db];
            if (model) {
                [models addObject:model];
            }
        }
    };
    OOMapTable *mt=classInfo.mapTable;
    OODatabase *db=classInfo.database;
    if (db) {
        [db inDB:^(OODatabase *db) {
            [db beginTransaction];
            block(mt,db,YES);
            [db commit];
        }];
    }else{
        block(mt,db,NO);
    }
    return models?models:nil;
}
+ (instancetype)oo_modelWithJson:(id)json{
    OOClassInfo *classInfo=[self oo_classInfo];
    OOMapTable *mt=classInfo.mapTable;
    OODatabase *db=classInfo.database;
    return [self oo_modelWithJson:json classInfo:classInfo mt:mt db:db];
}

+ (instancetype)oo_modelWithUniqueValue:(id)uniqueValue{
    OOClassInfo *classInfo=[self oo_classInfo];
    OOMapTable *mt=classInfo.mapTable;
    OODatabase *db=classInfo.database;
    return [self oo_modelWithTransformedUniqueValue:uniqueValue classInfo:classInfo mt:mt db:db];
}

+ (NSArray *)oo_modelsWithAfterWhereSql:(NSString*)afterWhereSql arguments:(NSArray*)arguments{
    OOClassInfo *classInfo=[self oo_classInfo];
    OOMapTable *mt=classInfo.mapTable;
    OODatabase *db=classInfo.database;
    return [self oo_modelsWithAfterWhereSql:afterWhereSql arguments:arguments classInfo:classInfo mt:mt db:db];
}

#pragma mark --
#pragma mark -- json

+ (instancetype)oo_modelWithJson:(id)json classInfo:(OOClassInfo*)classInfo mt:(OOMapTable*)mt db:(OODatabase*)db{
    if ([json isKindOfClass:[NSString class]]) {
        return [self oo_modelWithJsonString:json classInfo:classInfo mt:mt db:db];
    }else if ([json isKindOfClass:[NSDictionary class]]){
        return [self oo_modelWithJsonDictionary:json classInfo:classInfo mt:mt db:db];
    }else{
        NSLog(@"json is not a string or dictionary!---%@",json);
    }
    return nil;
}

+ (instancetype)oo_modelWithJsonString:(NSString*)jsonString classInfo:(OOClassInfo*)classInfo mt:(OOMapTable*)mt db:(OODatabase*)db{
    id json=[NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    if ([json isKindOfClass:NSDictionary.class]) {
        return [self oo_modelWithJsonDictionary:json classInfo:classInfo mt:mt db:db];
    }
    NSLog(@"jsonString can not serializate to object!---%@",jsonString);
    return nil;
}

+ (instancetype)oo_modelWithJsonDictionary:(NSDictionary*)jsonDictionary classInfo:(OOClassInfo*)classInfo mt:(OOMapTable*)mt db:(OODatabase*)db{
    if (![jsonDictionary isKindOfClass:NSDictionary.class]) {
        NSLog(@"jsonDictionary must be a dictionary!---%@",jsonDictionary);
        return nil;
    }
    NSString * uniqueKey=classInfo.uniquePropertyKey;
    OOPropertyInfo *propertyInfo=classInfo.propertyInfosByPropertyKeys[uniqueKey];
    id uniqueValue=jsonDictionary[propertyInfo.jsonKeyPath];
    NSValueTransformer *jsonValueTransformer=propertyInfo.jsonValueTransformer;
    if (jsonValueTransformer) {
        uniqueValue=[jsonValueTransformer transformedValue:uniqueValue];
    }
    if (!uniqueValue) {
        NSLog(@"json dictionary must have unique key value!---%@",jsonDictionary);
        return nil;
    }
    id  model=[self oo_modelWithTransformedUniqueValue:uniqueValue classInfo:classInfo mt:mt db:db];
    [model oo_setIsReplaced:YES];
    if (!model) {
        model=[[self alloc]init];
        [model oo_mergeWithJsonDictionary:jsonDictionary];
        [model oo_setIsReplaced:NO];
        [model oo_insert:classInfo db:db];
    }else{
        [model oo_mergeWithJsonDictionary:jsonDictionary];
        [model oo_update:classInfo db:db];
    }
    [model oo_mergeWithJsonDictionary:jsonDictionary];
    return model;
}

- (void)oo_mergeWithJson:(id)json{
    if ([json isKindOfClass:NSString.class]) {
        [self oo_mergeWithJsonString:json];
    }else if([json isKindOfClass:NSDictionary.class]){
        [self oo_mergeWithJsonDictionary:json];
    }else{
        NSLog(@"json is not a string or dictionary!---%@",json);
    }
}

- (void)oo_uniqueValue{
    
}

- (void)oo_mergeWithJsonString:(NSString*)string{
    id json=[NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    if ([json isKindOfClass:NSDictionary.class]) {
        [self oo_mergeWithJsonDictionary:json];
    }
}

- (void)oo_mergeWithJsonDictionary:(NSDictionary*)jsonDictionary{
    OOModelContext context={0};
    context.model=(__bridge void*)self;
    context.storage=(__bridge void *)jsonDictionary;
    CFArrayRef propertyInfos=(__bridge CFArrayRef)[self.class oo_classInfo].jsonPropertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_set_value_for_property_apply,&context);
}

- (NSDictionary*)oo_jsonDictionary{
    NSMutableDictionary *jsonDictionary=[NSMutableDictionary dictionary];
    OOModelContext context={0};
    context.model=(__bridge void *)self;
    context.storage=(__bridge void *)jsonDictionary;
    CFArrayRef propertyInfos=(__bridge CFArrayRef)[self.class oo_classInfo].jsonPropertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_get_value_for_property_apply,&context);
    return jsonDictionary;
}

- (NSString*)oo_jsonString{
    return [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:self.oo_jsonDictionary options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
}
#pragma mark --
#pragma mark -- value
+ (instancetype)oo_modelWithTransformedUniqueValue:(id)value classInfo:(OOClassInfo*)classInfo mt:(OOMapTable*)mt db:(OODatabase*)db{
    __block id model=nil;
    [mt inMt:^(OOMapTable *mt) {
        model=[mt objectForKey:value];
    }];
    if (!model) {
        model=[[self oo_modelsWithAfterWhereSql:[NSString stringWithFormat:@"%@=?",OOCOMPACT(classInfo.uniquePropertyKey)] arguments:@[value] classInfo:classInfo mt:mt db:db ] lastObject];
    }
    return model;
}

//search in db
+ (NSArray *)oo_modelsWithAfterWhereSql:(NSString*)afterWhereSql arguments:(NSArray*)arguments classInfo:(OOClassInfo*)classInfo mt:(OOMapTable*)mt db:(OODatabase*)db{
    NSArray * results=[self oo_modelsWithAfterWhereSql:afterWhereSql arguments:arguments classInfo:classInfo db:db];
    if (!results) {
        return nil;
    }
    if (!mt) {
        return results;
    }
    NSMutableArray *models=[NSMutableArray array];
    OOPropertyInfo * uniquePropertyInfo=classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
    [mt inMt:^(OOMapTable *mt) {
        for (int i=0;i<results.count;i++){
            id dbModel=results[i];
            __block id mtModel=nil;
            id value=nil;;
            oo_get_object_for_property(dbModel, &value,uniquePropertyInfo);
            if (!value) {
                NSLog(@"db model does not have a unique value!---%@",dbModel);
                return;
            }
            mtModel=[mt objectForKey:value];
            if (mtModel) {
                [models addObject:mtModel];
            }else{
                [mt setObject:dbModel forKey:value];
                [models addObject:dbModel];
            }
        }
    }];
    return models;
}
// search in db only
+ (NSArray *)oo_modelsWithAfterWhereSql:(NSString*)afterWhereSql arguments:(NSArray*)arguments classInfo:(OOClassInfo*)classInfo db:(OODatabase*)db{
    if (!db) {
        return nil;
    }
    [self oo_createTableIfNeed:classInfo db:db];
    NSMutableArray *models=[NSMutableArray array];
    CFArrayRef propertyInfos=(__bridge CFArrayRef)classInfo.dbPropertyInfos;
    NSMutableString *sql=nil;
    if (afterWhereSql.length>0) {
        sql=[NSMutableString string];
        [sql insertString:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE ",classInfo.dbTable] atIndex:0];
        [sql appendString:afterWhereSql];
    }else{
        sql=[[NSString stringWithFormat:@"SELECT * FROM %@",classInfo.dbTable] mutableCopy];
    }
    NSArray *results=[db executeQuery:sql arguments:arguments];
    [results enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
        id model=[[[classInfo cls] alloc]init];
        OOModelContext context={0};
        context.model=(__bridge void*)model;
        context.storage=(__bridge void *)result;
        CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_set_value_for_property_apply_db,&context);
        [models addObject:model];
    }];
    return models?models:nil;
}

//- (BOOL)oo_saveToDb:(OOClassInfo*)classInfo db:(OODatabase*)db{
//    if (classInfo.conformsToOOUniqueModel) {
//        if (![self oo_insertToDb:classInfo db:db]) {
//            [self oo_updateToDb:classInfo db:db];
//            return YES;
//        }
//    }else{
//        [self oo_insertToDb:classInfo db:db];
//    }
//    return NO;
//}

- (BOOL)oo_update:(OOClassInfo*)classInfo db:(OODatabase*)db{
    NSMutableString *sql=[NSMutableString string];
    NSMutableArray *arguments=[NSMutableArray array];
    CFArrayRef propertyInfos=(__bridge CFArrayRef)classInfo.dbPropertyInfos;
    OOModelDbUpdateContext context={0};
    context.sql=(__bridge void *)sql;
    context.arguments=(__bridge void*)arguments;
    context.model=(__bridge void *)self;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_db_update_apply, &context);
    if (sql.length>0) {
        [sql insertString:[NSString stringWithFormat:@"UPDATE %@ SET ",classInfo.dbTable] atIndex:0];
        [sql appendFormat:@"%@=? WHERE %@=?",oo_latest_used_timestamp,OOCOMPACT(classInfo.uniquePropertyKey)];
        [arguments addObject:@([[NSDate date] timeIntervalSince1970])];
        OOPropertyInfo *uniquePropertyInfo=classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
        id uniqueValue;
        oo_get_object_for_property(self, &uniqueValue,uniquePropertyInfo);
        [arguments addObject:uniqueValue];
        return [db executeUpdate:sql arguments:arguments];
    }
    return YES;
}

- (BOOL)oo_insert:(OOClassInfo*)classInfo db:(OODatabase*)db{
    NSMutableString *sql1=[NSMutableString string];
    NSMutableString *sql2=[NSMutableString string];
    NSMutableArray *arguments=[NSMutableArray array];
    CFArrayRef propertyInfos=(__bridge CFArrayRef)classInfo.dbPropertyInfos;
    OOModelDbInsertContext context={0};
    context.sql1=(__bridge void *)sql1;
    context.sql2=(__bridge void *)sql2;
    context.arguments=(__bridge void*)arguments;
    context.model=(__bridge void *)self;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_db_insert_apply, &context);
    if (sql1.length>0&&sql2.length>0) {
        [sql1 appendString:oo_latest_used_timestamp];
        [sql1 insertString:@"(" atIndex:0];
        [sql1 appendString:@")"];
        [sql2 appendString:@"?"];
        [sql2 insertString:@"(" atIndex:0];
        [sql2 appendString:@")"];
        NSString *sql=[NSString stringWithFormat:@"INSERT INTO %@ %@ VALUES %@",classInfo.dbTable,sql1,sql2];
        [arguments addObject:@([[NSDate date]timeIntervalSince1970])];
        return [db executeUpdate:sql arguments:arguments];
    }
    return YES;
}

+ (BOOL)oo_createTableIfNeed:(OOClassInfo*)classInfo db:(OODatabase*)db{
    if(classInfo.dbTimestamp!=db.dbTimestamp){
        [self oo_createTable:classInfo db:db];
        [self oo_addColumn:classInfo db:db];
        [self oo_addIndexes:classInfo db:db];
        classInfo.dbTimestamp=db.dbTimestamp;
    }
    return YES;
}

+ (void)oo_createTable:(OOClassInfo*)classInfo db:(OODatabase*)db{
    NSString * table=classInfo.dbTable;
    if (![self oo_checkTable:table db:db]) {
        NSString *sql;
        if ([self conformsToProtocol:@protocol(OOUniqueModel)]) {
            NSString *uniquePropertyKey=[self.class uniquePropertyKey];
            OOPropertyInfo *propertyInfo=classInfo.propertyInfosByPropertyKeys[uniquePropertyKey];
            NSString *uniqueDbColumn=propertyInfo.dbColumn;
            NSString * uniqueDbColumnType=oo_databaseColumnTypeWithType(propertyInfo.dbColumnType);
            sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'%@' %@ NOT NULL UNIQUE,'%@' REAL)",table,uniqueDbColumn,uniqueDbColumnType,oo_latest_used_timestamp];
        }else{
            sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'%@' REAL)",table,oo_latest_used_timestamp];
        }
        [db executeUpdate:sql arguments:nil];
    }
}

+ (void)oo_addColumn:(OOClassInfo*)classInfo db:(OODatabase*)db{
    NSString * table=classInfo.dbTable;
    [classInfo.dbPropertyInfos enumerateObjectsUsingBlock:^(OOPropertyInfo * _Nonnull propertyInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([propertyInfo.propertyKey isEqualToString:classInfo.uniquePropertyKey]) {
            return;
        }
        if (![self oo_checkTable:table column:propertyInfo.dbColumn db:db]) {
            NSString *dbColumnType=oo_databaseColumnTypeWithType(propertyInfo.dbColumnType);
            NSString *sql=[NSString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN '%@' %@",table,propertyInfo.dbColumn,dbColumnType];
            [db executeUpdate:sql arguments:nil];
        }
    }];
}

+ (void)oo_addIndexes:(OOClassInfo*)classInfo db:(OODatabase*)db{
    NSMutableArray *databaseIndexesKeys=[NSMutableArray array];
    if ([self respondsToSelector:@selector(dbIndexesInPropertyKeys)]) {
        NSArray *indexesKeys=[self.class dbIndexesInPropertyKeys];
        [indexesKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSUInteger idx, BOOL * _Nonnull stop) {
            NSParameterAssert([propertyKey isKindOfClass:NSString.class]);
            NSString *column=OOCOMPACT(propertyKey);
            [databaseIndexesKeys addObject:column];
        }];
    }
    [databaseIndexesKeys addObject:oo_latest_used_timestamp];
    [databaseIndexesKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull databaseIndexKey, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self oo_checkTable:classInfo.dbTable index:databaseIndexKey db:db]) {
            NSString *index=[NSString stringWithFormat:@"%@_%@_index",classInfo.dbTable,databaseIndexKey];
            NSString *sql=[NSString stringWithFormat:@"CREATE INDEX %@ on %@(%@)",index,classInfo.dbTable,databaseIndexKey];
            [db executeUpdate:sql arguments:nil];
        }
    }];
}
+ (void)oo_deleteModelsBeforeDate:(NSDate*)date{
    OOClassInfo *classInfo=[self oo_classInfo];
    OODatabase *db=classInfo.database;
    [self oo_deleteModelsBeforeDate:date classInfo:classInfo db:db];
}
+ (void)oo_deleteModelsBeforeDate:(NSDate*)date classInfo:(OOClassInfo*)classInfo db:(OODatabase*)db{
    NSString *sql=[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@<%f",classInfo.dbTable,oo_latest_used_timestamp,[date timeIntervalSince1970]];
    [db executeUpdate:sql arguments:nil];
}

- (void)oo_modelEncode:(NSCoder *)aCoder{
    OOClassInfo *classInfo=[self.class oo_classInfo];
    OOModelContext context={0};
    context.model=(__bridge void *)self;
    context.storage=(__bridge void *)aCoder;
    CFArrayRef propertyInfos=(__bridge CFArrayRef)classInfo.propertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_encode_apply,&context);
}

- (id)oo_modelDecode:(NSCoder *)aDecoder{
    OOClassInfo *classInfo=[self.class oo_classInfo];
    OOModelContext context={0};
    context.model=(__bridge void *)self;
    context.storage=(__bridge void *)aDecoder;
    CFArrayRef propertyInfos=(__bridge CFArrayRef)classInfo.propertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_decode_apply,&context);
    return self;
}

#pragma mark --
#pragma mark -- getter setter

- (void)oo_setIsReplaced:(bool)isReplaced{
    static NSString *key=@"oo_isReplaced";
    [self willChangeValueForKey:key];
    objc_setAssociatedObject(self, @selector(oo_isReplaced), @(isReplaced), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:key];
}

- (bool)oo_isReplaced{
    return [objc_getAssociatedObject(self, @selector(oo_isReplaced)) boolValue];
}
#pragma mark --
#pragma mark -- check func

+ (BOOL)oo_checkTable:(NSString*)table db:(OODatabase*)db{
    NSString * sql=@"SELECT * FROM sqlite_master WHERE tbl_name=? AND type='table'";
    NSArray * sets=[db executeQuery:sql arguments:@[table]];
    if (sets.count>0) {
        return YES;
    }else{
        return NO;
    }
}

+ (BOOL)oo_checkTable:(NSString*)table column:(NSString*)column db:(OODatabase*)db{
    BOOL ret=NO;
    NSString * sql=@"SELECT * FROM sqlite_master WHERE tbl_name=? AND type='table'";
    NSArray * sets=[db executeQuery:sql arguments:@[table]];
    column=[NSString stringWithFormat:@"'%@'",column];
    if (sets.count>0) {
        for(NSDictionary * set in sets) {
            NSString *createSql=set[@"sql"];
            if (createSql&&[createSql rangeOfString:column].location!=NSNotFound) {
                ret=YES;
                break;
            }
        }
    }
    return ret;
}

+ (BOOL)oo_checkTable:(NSString*)table index:(NSString*)index db:(OODatabase*)db{
    __block BOOL ret;
    NSString * sql=@"SELECT * FROM sqlite_master WHERE tbl_name=? AND type='index'";
    ret=NO;
    NSArray * sets=[db executeQuery:sql arguments:@[table]];
    index=[NSString stringWithFormat:@"(%@)",index];
    if (sets.count>0) {
        for(NSDictionary * set in sets) {
            NSString *createSql=set[@"sql"];
            if (createSql&&[createSql rangeOfString:index].location!=NSNotFound) {
                ret=YES;
                break;
            }
        }
    }
    return ret;
}

+ (BOOL)oo_checkTable:(NSString*)table primaryKey:(NSString*)key primaryValue:(id)value db:(OODatabase*)db{
    NSParameterAssert(value);
    NSString *sql=[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=?",table,key];
    NSArray * sets=[db executeQuery:sql arguments:@[value]];
    if (sets.count>0) {
        return YES;
    }else{
        return NO;
    }
}

+ (OOClassInfo*)oo_classInfo{
    CFMutableDictionaryRef classInfoRoot=[self oo_classInfoRoot];
    @synchronized(NSObject.class) {
        OOClassInfo * classInfo=CFDictionaryGetValue(classInfoRoot, (__bridge void *)self);
        if (!classInfo) {
            classInfo=[OOClassInfo classInfoWithClass:self];
            CFDictionarySetValue(classInfoRoot, (__bridge void *)self, (__bridge void *)classInfo);
        }
        return classInfo;
    }
}

+ (CFMutableDictionaryRef)oo_classInfoRoot{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        oo_class_info_root=CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    });
    return oo_class_info_root;
}

+ (void)oo_setGlobalDB:(OODatabase*)db{
    NSDictionary * classInfoRoot=(__bridge NSDictionary*)[self oo_classInfoRoot];
    [OOClassInfo setGlobalDatabase:db];
    NSLock *lock=[OOClassInfo globalLock];
    [lock lock];
        [classInfoRoot enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, OOClassInfo * _Nonnull classInfo, BOOL * _Nonnull stop) {
            classInfo.database=db;
            [classInfo.database open];
            classInfo.mapTable=[[OOMapTable alloc]initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        }];
    [lock unlock];
}

+ (void)oo_setDb:(OODatabase*)db{
    NSLock *lock=[OOClassInfo globalLock];
    [lock lock];
    [self oo_classInfo].database=db;
    [lock unlock];
}
@end
