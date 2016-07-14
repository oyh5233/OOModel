//
//  NSObject+OOModel.m
//  OOModel
//

#import "NSObject+OOModel.h"
#import <objc/message.h>
#import "OODatabase.h"

const NSString * oo_compaction_prefix    = @"oo_";
static NSString * oo_latest_use_timestamp = @"oo_latest_use_timestamp";
static OODatabase *oo_db=nil;

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
    __unsafe_unretained NSValueTransformer *valueTransformer=propertyInfo.jsonValueTransformer;
    if (valueTransformer) {
        value=[model valueForKey:propertyInfo.propertyKey];
        value=[valueTransformer reverseTransformedValue:value];
    }else{
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
    NSMutableArray *models=[NSMutableArray array];
    void(^block)()=^{
        for (int i=0;i<jsonDictionaries.count;i++){
            NSDictionary *json=jsonDictionaries[i];
            id model=[self oo_modelWithJson:json];
            if (model) {
                [models addObject:model];
            }
        }
    };
    if (oo_db) {
        [oo_db inDB:^(OODatabase *db){
            [db beginTransaction];
            block();
            [db commit];
        }];
    }else{
        block();
    }
    return models;
}

+ (instancetype)oo_modelWithJson:(id)json{
    if ([json isKindOfClass:[NSString class]]) {
        return [self oo_modelWithJsonString:json];
    }else if ([json isKindOfClass:[NSDictionary class]]){
        return [self oo_modelWithJsonDictionary:json];
    }
    return nil;
}

+ (instancetype)oo_modelWithJsonString:(NSString*)jsonString{
    id json=[NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    if ([json isKindOfClass:NSDictionary.class]) {
        return [self oo_modelWithJsonDictionary:json];
    }
    return nil;
}

+ (instancetype)oo_modelWithJsonDictionary:(NSDictionary*)jsonDictionary{
    if (![jsonDictionary isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    OOClassInfo *classInfo=[self oo_classInfo];
    [self.class oo_createTableIfNeed:classInfo];
    if (classInfo.conformsToOOUniqueModel) {
        NSString * uniqueKey=[self.class uniquePropertyKey];
        OOPropertyInfo *propertyInfo=classInfo.propertyInfosByPropertyKeys[uniqueKey];
        id uniqueValue=jsonDictionary[propertyInfo.jsonKeyPath];
        NSValueTransformer *jsonValueTransformer=propertyInfo.jsonValueTransformer;
        if (jsonValueTransformer) {
            uniqueValue=[jsonValueTransformer transformedValue:uniqueValue];
        }
        if (uniqueValue) {
            id mapTableModel=[self oo_modelInMapTableWithUniqueTransformedValue:uniqueValue classInfo:classInfo];
            if (mapTableModel) {
                [mapTableModel setIsReplaced:YES];
                [mapTableModel oo_mergeWithJsonDictionary:jsonDictionary];
                if (classInfo.conformsToOODbModel) {
                    [mapTableModel oo_updateToDb:classInfo];
                }
                return mapTableModel;
            }
            id newModel=[[self alloc]init];
            if (newModel) {
                [newModel oo_mergeWithJsonDictionary:jsonDictionary];
                if (classInfo.conformsToOODbModel) {
                    if([newModel oo_saveToDb:classInfo]){
                        [newModel setIsReplaced:YES];
                    }
                    newModel=[self oo_modelInDbWithUniqueTransformedValue:uniqueValue classInfo:classInfo];
                }
                [classInfo.mapTable setObject:newModel forKey:uniqueValue];
                return newModel;
            }
        }
        return nil;
    }
    id model=[[self alloc]init];
    if (model) {
        [model oo_mergeWithJsonDictionary:jsonDictionary];
    }
    if (classInfo.conformsToOODbModel) {
        [model oo_saveToDb:classInfo];
    }
    return model;
}

- (void)oo_mergeWithJson:(id)json{
    if ([json isKindOfClass:NSString.class]) {
        [self oo_mergeWithJsonString:json];
    }else if([json isKindOfClass:NSDictionary.class]){
        [self oo_mergeWithJsonDictionary:json];
    }
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
    CFArrayRef propertyInfos=(__bridge CFArrayRef)[self.class oo_classInfo].propertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_set_value_for_property_apply,&context);
}

- (NSDictionary*)oo_jsonDictionary{
    NSMutableDictionary *jsonDictionary=[NSMutableDictionary dictionary];
    OOModelContext context={0};
    context.model=(__bridge void *)self;
    context.storage=(__bridge void *)jsonDictionary;
    CFArrayRef propertyInfos=(__bridge CFArrayRef)[self.class oo_classInfo].propertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_get_value_for_property_apply,&context);
    return jsonDictionary;
}

- (NSString*)oo_jsonString{
    return [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:self.oo_jsonDictionary options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
}

+ (instancetype)oo_modelWithUniqueValue:(id)value{
    OOClassInfo *classInfo=[self oo_classInfo];
    if (!classInfo.conformsToOOUniqueModel) {
        return nil;
    }
    [self.class oo_createTableIfNeed:classInfo];
    return [self oo_modelWithUniqueValue:value classInfo:classInfo];
}

+ (instancetype)oo_modelWithUniqueValue:(id)value classInfo:(OOClassInfo*)classInfo{
    OOPropertyInfo *propertyInfo=classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
    if (propertyInfo.dbValueTransformer) {
        value=[propertyInfo.dbValueTransformer reverseTransformedValue:value];
    }
    if (!value) {
        return nil;
    }
    id model=[self oo_modelInMapTableWithUniqueTransformedValue:value classInfo:classInfo];
    if (model) {
        return model;
    }
    if (classInfo.conformsToOODbModel) {
        id model=[self oo_modelInDbWithUniqueTransformedValue:value classInfo:classInfo];
        [self oo_saveToMapTable:model forKey:value classInfo:classInfo];
        return model;
    }
    model =[[self alloc]init];
    if (propertyInfo.jsonForwards) {
        value=((id (*)(Class, SEL,id))(void *) objc_msgSend)(propertyInfo.propertyCls,propertyInfo.jsonForwards,value);
        if (!oo_set_object_for_property(model, value, propertyInfo)) {
            return nil;
        }
    }else{
        if (!oo_set_object_for_property(model, value, propertyInfo)) {
            return nil;
        }
    }
    if (classInfo.conformsToOODbModel) {
        [model oo_saveToDb:classInfo];
    }
    [self oo_saveToMapTable:model forKey:value classInfo:classInfo];
    return model;
}

+ (instancetype)oo_modelInMapTableWithUniqueTransformedValue:(id)value classInfo:(OOClassInfo*)classInfo{
    NSMapTable *mapTable=classInfo.mapTable;
    dispatch_semaphore_wait(classInfo.mapTableSemaphore, DISPATCH_TIME_FOREVER);
    id model=[mapTable objectForKey:value];
    dispatch_semaphore_signal(classInfo.mapTableSemaphore);
    return model;
}

+ (void)oo_saveToMapTable:(id)model forKey:value classInfo:(OOClassInfo*)classInfo{
    dispatch_semaphore_wait(classInfo.mapTableSemaphore, DISPATCH_TIME_FOREVER);
    [classInfo.mapTable setObject:model forKey:value];
    dispatch_semaphore_signal(classInfo.mapTableSemaphore);
}
+ (BOOL)oo_openDb:(NSString*)file{
    if (oo_db) {
        if ([oo_db.file isEqualToString:file]) {
            return YES;
        }
        [oo_db close];
    }
    oo_db=[OODatabase databaseWithFile:file];
    return [oo_db open];
}

+ (instancetype)oo_modelInDbWithUniqueTransformedValue:(id)value classInfo:(OOClassInfo*)classInfo{
    return [[self oo_modelsInDbWithAfterWhereSql:[NSString stringWithFormat:@"%@=?",OOCOMPACT(classInfo.uniquePropertyKey)] arguments:@[value] classInfo:classInfo] lastObject];
}

+ (NSArray *)oo_modelsWithAfterWhereSql:(NSString*)afterWhereSql arguments:(NSArray*)arguments{
    OOClassInfo *classInfo=[self oo_classInfo];
    NSArray * results=[self oo_modelsInDbWithAfterWhereSql:afterWhereSql arguments:arguments classInfo:classInfo];
    if (!classInfo.conformsToOOUniqueModel) {
        return results;
    }
    NSMutableArray *models=[NSMutableArray array];
    OOPropertyInfo * uniquePropertyInfo=classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
    for (int i=0;i<results.count;i++){
        id model=results[i];
        id mapTableModel;
        id value;
        oo_get_object_for_property(model, &value,uniquePropertyInfo);
        if (value) {
            mapTableModel=[self oo_modelInMapTableWithUniqueTransformedValue:value classInfo:classInfo];
        }
        if (mapTableModel) {
            [models addObject:mapTableModel];
        }else{
            [self oo_saveToMapTable:model forKey:value classInfo:classInfo];
            [models addObject:model];
        }
    }
    return models;
}

+ (NSArray *)oo_modelsInDbWithAfterWhereSql:(NSString*)afterWhereSql arguments:(NSArray*)arguments classInfo:(OOClassInfo*)classInfo{
    [self oo_createTableIfNeed:classInfo];
    NSMutableArray *models=[NSMutableArray array];
    CFArrayRef propertyInfos=(__bridge CFArrayRef)classInfo.propertyInfos;
    NSMutableString *sql=nil;
    if (afterWhereSql.length>0) {
        sql=[NSMutableString string];
        [sql insertString:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE ",classInfo.dbTable] atIndex:0];
        [sql appendString:afterWhereSql];
    }else{
        sql=[[NSString stringWithFormat:@"SELECT * FROM %@",classInfo.dbTable] mutableCopy];
    }
    NSArray *results=[oo_db executeQuery:sql arguments:arguments];
    [results enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
        id model=[[[classInfo cls] alloc]init];
        OOModelContext context={0};
        context.model=(__bridge void*)model;
        context.storage=(__bridge void *)result;
        CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_set_value_for_property_apply_db,&context);
        [models addObject:model];
    }];
    return models;
}

- (BOOL)oo_saveToDb:(OOClassInfo*)classInfo{
    if (classInfo.conformsToOOUniqueModel) {
        if (![self oo_insertToDb:classInfo]) {
            [self oo_updateToDb:classInfo];
            return YES;
        }
    }else{
        [self oo_insertToDb:classInfo];
    }
    return NO;
}

- (BOOL)oo_updateToDb:(OOClassInfo*)classInfo{
    NSMutableString *sql=[NSMutableString string];
    NSMutableArray *arguments=[NSMutableArray array];
    CFArrayRef propertyInfos=(__bridge CFArrayRef)classInfo.propertyInfos;
    OOModelDbUpdateContext context={0};
    context.sql=(__bridge void *)sql;
    context.arguments=(__bridge void*)arguments;
    context.model=(__bridge void *)self;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_db_update_apply, &context);
    if (sql.length>0) {
        [sql insertString:[NSString stringWithFormat:@"UPDATE %@ SET ",classInfo.dbTable] atIndex:0];
        [sql appendFormat:@"%@=? WHERE %@=?",oo_latest_use_timestamp,OOCOMPACT(classInfo.uniquePropertyKey)];
        [arguments addObject:@([[NSDate date] timeIntervalSince1970])];
        OOPropertyInfo *uniquePropertyInfo=classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
        id uniqueValue;
        oo_get_object_for_property(self, &uniqueValue,uniquePropertyInfo);
        [arguments addObject:uniqueValue];
        return [oo_db executeUpdate:sql arguments:arguments];
    }
    return YES;
}

- (BOOL)oo_insertToDb:(OOClassInfo*)classInfo{
    NSMutableString *sql1=[NSMutableString string];
    NSMutableString *sql2=[NSMutableString string];
    NSMutableArray *arguments=[NSMutableArray array];
    CFArrayRef propertyInfos=(__bridge CFArrayRef)classInfo.propertyInfos;
    OOModelDbInsertContext context={0};
    context.sql1=(__bridge void *)sql1;
    context.sql2=(__bridge void *)sql2;
    context.arguments=(__bridge void*)arguments;
    context.model=(__bridge void *)self;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_db_insert_apply, &context);
    if (sql1.length>0&&sql2.length>0) {
        [sql1 appendString:oo_latest_use_timestamp];
        [sql1 insertString:@"(" atIndex:0];
        [sql1 appendString:@")"];
        [sql2 appendString:@"?"];
        [sql2 insertString:@"(" atIndex:0];
        [sql2 appendString:@")"];
        NSString *sql=[NSString stringWithFormat:@"INSERT INTO %@ %@ VALUES %@",classInfo.dbTable,sql1,sql2];
        [arguments addObject:@([[NSDate date]timeIntervalSince1970])];
        return [oo_db executeUpdate:sql arguments:arguments];
    }
    return YES;
}

+ (void)oo_createTableIfNeed:(OOClassInfo*)classInfo{
    if(classInfo.dbTimestamp==oo_db.dbTimestamp){
        return;
    }
    [self oo_createTable:classInfo];
    [self oo_addColumn:classInfo];
    [self oo_addIndexes:classInfo];
    classInfo.dbTimestamp=oo_db.dbTimestamp;
}

+ (void)oo_createTable:(OOClassInfo*)classInfo{
    NSString * table=classInfo.dbTable;
    if (![self oo_checkTable:table db:oo_db]) {
        NSString *sql;
        if ([self conformsToProtocol:@protocol(OOUniqueModel)]) {
            NSString *uniquePropertyKey=[self.class uniquePropertyKey];
            OOPropertyInfo *propertyInfo=classInfo.propertyInfosByPropertyKeys[uniquePropertyKey];
            NSString *uniqueDbColumn=propertyInfo.dbColumn;
            NSString * uniqueDbColumnType=oo_databaseColumnTypeWithType(propertyInfo.dbColumnType);
            sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'%@' %@ NOT NULL UNIQUE,'%@' REAL)",table,uniqueDbColumn,uniqueDbColumnType,oo_latest_use_timestamp];
        }else{
            sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'%@' REAL)",table,oo_latest_use_timestamp];
        }
        [oo_db executeUpdate:sql arguments:nil];
    }
}

+ (void)oo_addColumn:(OOClassInfo*)classInfo{
    NSString * table=classInfo.dbTable;
    [classInfo.propertyInfos enumerateObjectsUsingBlock:^(OOPropertyInfo * _Nonnull propertyInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([propertyInfo.propertyKey isEqualToString:classInfo.uniquePropertyKey]) {
            return;
        }
        if (![self oo_checkTable:table column:propertyInfo.dbColumn db:oo_db]) {
            NSString *dbColumnType=oo_databaseColumnTypeWithType(propertyInfo.dbColumnType);
            NSString *sql=[NSString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN '%@' %@",table,propertyInfo.dbColumn,dbColumnType];
            [oo_db executeUpdate:sql arguments:nil];
        }
    }];
}

+ (void)oo_addIndexes:(OOClassInfo*)classInfo{
    NSMutableArray *databaseIndexesKeys=[NSMutableArray array];
    if ([self respondsToSelector:@selector(dbIndexesInPropertyKeys)]) {
        NSArray *indexesKeys=[self.class dbIndexesInPropertyKeys];
        [indexesKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSUInteger idx, BOOL * _Nonnull stop) {
            NSParameterAssert([propertyKey isKindOfClass:NSString.class]);
            NSString *column=OOCOMPACT(propertyKey);
            [databaseIndexesKeys addObject:column];
        }];
    }
    [databaseIndexesKeys addObject:oo_latest_use_timestamp];
    [databaseIndexesKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull databaseIndexKey, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self oo_checkTable:classInfo.dbTable index:databaseIndexKey db:oo_db]) {
            NSString *index=[NSString stringWithFormat:@"%@_%@_index",classInfo.dbTable,databaseIndexKey];
            NSString *sql=[NSString stringWithFormat:@"CREATE INDEX %@ on %@(%@)",index,classInfo.dbTable,databaseIndexKey];
            [oo_db executeUpdate:sql arguments:nil];
        }
    }];
}

+ (void)oo_deleteModelsBeforeDate:(NSDate*)date{
    OOClassInfo *classInfo=[self oo_classInfo];
    NSString *sql=[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@<%f",classInfo.dbTable,oo_latest_use_timestamp,[date timeIntervalSince1970]];
    [oo_db executeUpdate:sql arguments:nil];
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

- (void)setIsReplaced:(bool)isReplaced{
    [self willChangeValueForKey:@"isReplaced"];
    objc_setAssociatedObject(self, @selector(isReplaced), @(isReplaced), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"isReplaced"];
}

- (bool)isReplaced{
    return [objc_getAssociatedObject(self, @selector(isReplaced)) boolValue];
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
    NSString * sql=@"SELECT sql FROM sqlite_master WHERE tbl_name=? AND type='table'";
    NSArray * sets=[db executeQuery:sql arguments:@[table]];
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
    @synchronized(self) {
        static CFMutableDictionaryRef classInfoRoot;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            classInfoRoot=CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        });
        OOClassInfo * classInfo=CFDictionaryGetValue(classInfoRoot, (__bridge void *)self);
        if (!classInfo) {
            classInfo=[OOClassInfo classInfoWithClass:self];
            CFDictionarySetValue(classInfoRoot, (__bridge void *)self, (__bridge void *)classInfo);
        }
        return classInfo;
    }
}

@end
