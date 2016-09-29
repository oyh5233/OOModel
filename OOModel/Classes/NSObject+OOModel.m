//
//  NSObject+OOModel.m
//  OOModel
//

#import "NSObject+OOModel.h"
#import "OOMapTable.h"
#import <libkern/OSAtomic.h>
#import <objc/message.h>
static NSString *oo_latest_used_timestamp = @"oo_latest_used_timestamp";
static OODb *oo_global_db = nil;

typedef struct
{
    void *model;
    void *storage;

} OOModelContext;

typedef struct
{
    void *model;
    void *sql;
    void *arguments;
    void *uniqueValue;
} OOModelDbUpdateContext;

typedef struct
{
    void *model;
    void *sql1;
    void *sql2;
    void *arguments;
} OOModelDbInsertContext;

typedef struct
{
    void *sql;
    void *propertyInfos;
} OOModelReplaceContext;

inline static NSString *oo_databaseColumnTypeWithType(OODbColumnType type)
{
    NSString *dbColumnType = nil;
    switch (type)
    {
        case OODbColumnTypeText:
            dbColumnType = @"text";
            break;
        case OODbColumnTypeInteger:
            dbColumnType = @"integer";
            break;
        case OODbColumnTypeReal:
            dbColumnType = @"real";
            break;
        case OODbColumnTypeBlob:
            dbColumnType = @"blob";
            break;
        default:
            assert(NO);
            break;
    }
    return dbColumnType;
}

static inline id oo_json_value_from_value(__unsafe_unretained id value, OOPropertyInfo *propertyInfo)
{
    OOEncodingType encodingType = propertyInfo.encodingType;
    if (!value)
    {
        return nil;
    }
    if (encodingType & OOEncodingTypeObject)
    {
        switch (encodingType)
        {
            case OOEncodingTypeNSString:

            case OOEncodingTypeNSNumber:
                return value;
            case OOEncodingTypeNSURL:
                return [value absoluteString];
            case OOEncodingTypeNSDate:
                return @([value timeIntervalSince1970]);
            case OOEncodingTypeNSData:
                return [value base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            default:
            {
                OOClassInfo *propertyClassInfo = [propertyInfo.propertyCls oo_classInfo];
                if (propertyClassInfo.jsonPropertyInfos)
                {
                    value = [value oo_jsonDictionary];
                }
            }
            break;
        }
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        return value;
    }
    __unsafe_unretained NSValueTransformer *valueTransformer = propertyInfo.jsonValueTransformer;
    if (valueTransformer)
    {
        value = [valueTransformer reverseTransformedValue:value];
        return value;
    }
    NSLog(@"a property can not reverse to json---class:%@,propertyKey:%@", NSStringFromClass(propertyInfo.ownClassInfo.cls), propertyInfo.propertyKey);
    return nil;
}

static inline id oo_value_from_json_value(__unsafe_unretained id value, OOPropertyInfo *propertyInfo)
{
    OOEncodingType encodingType = propertyInfo.encodingType;
    if (encodingType & OOEncodingTypeObject)
    {
        switch (encodingType)
        {
            case OOEncodingTypeNSString:
                if ([value isKindOfClass:NSNumber.class])
                {
                    return [NSString stringWithFormat:@"%@", value];
                }
                return value;
            case OOEncodingTypeNSNumber:
                if ([value isKindOfClass:NSString.class])
                {
                    return @([value doubleValue]);
                }
                return value;
            case OOEncodingTypeNSDate:
                return [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
            case OOEncodingTypeNSURL:
                if ([value isKindOfClass:NSString.class])
                {
                    return [NSURL URLWithString:value];
                }
                break;
            case OOEncodingTypeNSData:
                if ([value isKindOfClass:NSString.class])
                {
                    return [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
                }
            default:
            {
                OOClassInfo *propertyClassInfo = [propertyInfo.propertyCls oo_classInfo];
                if (propertyClassInfo.jsonPropertyInfos)
                {
                    value = [[value class] oo_modelWithJsonDictionary:value];
                    return value;
                }
            }
            break;
        }
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        if ([value isKindOfClass:[NSString class]])
        {
            return @([value doubleValue]);
        }
        return value;
    }
    __unsafe_unretained NSValueTransformer *valueTransformer = propertyInfo.jsonValueTransformer;
    if (valueTransformer)
    {
        value = [valueTransformer transformedValue:value];
        return value;
    }
    NSLog(@"a property can not reverse to json---class:%@,propertyKey:%@", NSStringFromClass(propertyInfo.ownClassInfo.cls), propertyInfo.propertyKey);
    return nil;
}

static inline void oo_set_value_for_property(__unsafe_unretained id model, __unsafe_unretained id value, __unsafe_unretained OOPropertyInfo *propertyInfo)
{
    OOEncodingType encodingType = propertyInfo.encodingType;
    SEL setter = propertyInfo.setter;
    if (encodingType & OOEncodingTypeObject || encodingType == OOEncodingTypeUnknow)
    {
        if (value == nil || value == (id) kCFNull)
        {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, nil);
        }
        else
        {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, value);
        }
        return;
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        if (value == nil || value == (id) kCFNull)
        {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)(model, setter, 0);
            return;
        }
        switch (encodingType)
        {
            case OOEncodingTypeBool:
                if ([value respondsToSelector:@selector(boolValue)])
                {
                    ((void (*)(id, SEL, bool))(void *) objc_msgSend)(model, setter, [value boolValue]);
                }
                break;
            case OOEncodingTypeInt8:
                if ([value isKindOfClass:NSNumber.class])
                {
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, setter, [value charValue]);
                }
                else if ([value respondsToSelector:@selector(intValue)])
                {
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, setter, (char) [value intValue]);
                }
                break;
            case OOEncodingTypeUInt8:
                if ([value isKindOfClass:NSNumber.class])
                {
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, setter, [value unsignedCharValue]);
                }
                else if ([value respondsToSelector:@selector(intValue)])
                {
                    ((void (*)(id, SEL, UInt8))(void *) objc_msgSend)(model, setter, (UInt8)[value intValue]);
                }
                break;
            case OOEncodingTypeInt16:
                if ([value isKindOfClass:NSNumber.class])
                {
                    ((void (*)(id, SEL, short))(void *) objc_msgSend)(model, setter, [value shortValue]);
                }
                else if ([value respondsToSelector:@selector(intValue)])
                {
                    ((void (*)(id, SEL, short))(void *) objc_msgSend)(model, setter, (short) [value intValue]);
                }
                break;
            case OOEncodingTypeUInt16:
                if ([value isKindOfClass:NSNumber.class])
                {
                    ((void (*)(id, SEL, UInt16))(void *) objc_msgSend)(model, setter, [value unsignedShortValue]);
                }
                else if ([value respondsToSelector:@selector(intValue)])
                {
                    ((void (*)(id, SEL, UInt16))(void *) objc_msgSend)(model, setter, (UInt16)[value intValue]);
                }
                break;
            case OOEncodingTypeInt32:
                if ([value respondsToSelector:@selector(intValue)])
                {
                    ((void (*)(id, SEL, int))(void *) objc_msgSend)(model, setter, [value intValue]);
                }
                break;
            case OOEncodingTypeUInt32:
                if ([value isKindOfClass:NSNumber.class])
                {
                    ((void (*)(id, SEL, UInt32))(void *) objc_msgSend)(model, setter, [value unsignedIntValue]);
                }
                else if ([value respondsToSelector:@selector(intValue)])
                {
                    ((void (*)(id, SEL, UInt32))(void *) objc_msgSend)(model, setter, (UInt32)[value intValue]);
                }
                break;
            case OOEncodingTypeInt64:
                if ([value respondsToSelector:@selector(longLongValue)])
                {
                    ((void (*)(id, SEL, long long))(void *) objc_msgSend)(model, setter, (long long) [value longLongValue]);
                }
                break;
            case OOEncodingTypeUInt64:
                if ([value isKindOfClass:NSNumber.class])
                {
                    ((void (*)(id, SEL, UInt64))(void *) objc_msgSend)(model, setter, [value unsignedLongLongValue]);
                }
                else if ([value respondsToSelector:@selector(longLongValue)])
                {
                    ((void (*)(id, SEL, UInt64))(void *) objc_msgSend)(model, setter, (UInt64)[value longLongValue]);
                }
                break;
            case OOEncodingTypeFloat:
                if ([value respondsToSelector:@selector(floatValue)])
                {
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, setter, [value floatValue]);
                }
                break;
            case OOEncodingTypeDouble:
                if ([value respondsToSelector:@selector(doubleValue)])
                {
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, setter, [value doubleValue]);
                }
                break;
            default:
                break;
        }
    }
}

static inline id oo_get_value_for_property(__unsafe_unretained id model, __unsafe_unretained OOPropertyInfo *propertyInfo)
{
    id value = nil;
    OOEncodingType encodingType = propertyInfo.encodingType;
    SEL getter = propertyInfo.getter;
    if (encodingType & OOEncodingTypeObject)
    {
        value = ((id (*)(id, SEL))(void *) objc_msgSend)(model, getter);
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        switch (encodingType)
        {
            case OOEncodingTypeBool:
                value = @(((bool (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeInt8:
                value = @(((char (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeUInt8:
                value = @(((UInt8 (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeInt16:
                value = @(((short (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeUInt16:
                value = @(((UInt16 (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeInt32:
                value = @(((int (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeUInt32:
                value = @(((UInt32 (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeInt64:
                value = @(((long long (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeUInt64:
                value = @(((UInt64 (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeFloat:
                value = @(((float (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            case OOEncodingTypeDouble:
                value = @(((double (*)(id, SEL))(void *) objc_msgSend)(model, getter));
                break;
            default:
                break;
        }
    }
    else if (encodingType == OOEncodingTypeUnknow)
    {
        value = [model valueForKey:propertyInfo.propertyKey];
    }
    return value;
}

static inline void oo_set_json_value_for_property(__unsafe_unretained id model, __unsafe_unretained id value, __unsafe_unretained OOPropertyInfo *propertyInfo)
{
    oo_set_value_for_property(model, oo_value_from_json_value(value, propertyInfo), propertyInfo);
}

static inline id oo_get_json_value_for_property(__unsafe_unretained id model, __unsafe_unretained OOPropertyInfo *propertyInfo)
{
    return oo_json_value_from_value(oo_get_value_for_property(model, propertyInfo), propertyInfo);
}

static void oo_transform_json_dictionary_to_model_apply(const void *_value, void *_context)
{
    OOModelContext *context = _context;
    __unsafe_unretained NSDictionary *jsonDictionary = (__bridge id) context->storage;
    __unsafe_unretained id model = (__bridge id) context->model;
    __unsafe_unretained OOPropertyInfo *propertyInfo = (__bridge id) _value;
    __unsafe_unretained NSString *jsonKeyPathString = propertyInfo.jsonKeyPathInString;
    __unsafe_unretained NSArray *jsonKeyPathArray = propertyInfo.jsonKeyPathInArray;
    id jsonValue = jsonDictionary;
    if (jsonKeyPathArray.count < 2)
    {
        jsonValue = jsonDictionary[jsonKeyPathString];
    }
    else
    {
        NSInteger count = [jsonKeyPathArray count];
        NSInteger i = 0;
        for (; i < count; i++)
        {
            id nodeValue = jsonValue[jsonKeyPathArray[i]];
            if (nodeValue)
            {
                jsonValue = nodeValue;
            }
            else
            {
                break;
            }
        }
        if (i != count)
        {
            jsonValue = nil;
        }
    }
    if (!jsonValue)
    {
        return;
    }
    oo_set_json_value_for_property(model, jsonValue, propertyInfo);
}

static void oo_transform_model_to_dictionary_apply(const void *_value, void *_context)
{
    OOModelContext *context = _context;
    __unsafe_unretained id model = (__bridge id) context->model;
    __unsafe_unretained OOPropertyInfo *propertyInfo = (__bridge id) _value;
    __unsafe_unretained NSMutableDictionary *dictionary = (__bridge id) context->storage;
    id value = oo_get_value_for_property(model, propertyInfo);
    if (!value)
    {
        return;
    }
    dictionary[propertyInfo.propertyKey] = value;
}

static void oo_transform_model_to_json_dictionary_apply(const void *_value, void *_context)
{
    OOModelContext *context = _context;
    __unsafe_unretained id model = (__bridge id) context->model;
    __unsafe_unretained OOPropertyInfo *propertyInfo = (__bridge id) _value;
    __unsafe_unretained NSString *jsonKeyPathString = propertyInfo.jsonKeyPathInString;
    __unsafe_unretained NSArray *jsonKeyPathArray = propertyInfo.jsonKeyPathInArray;
    __unsafe_unretained NSMutableDictionary *jsonDictionary = (__bridge id) context->storage;
    id jsonValue = oo_get_json_value_for_property(model, propertyInfo);
    if (!jsonValue)
    {
        return;
    }
    NSMutableDictionary *parent = jsonDictionary;
    if (jsonKeyPathArray.count < 2)
    {
        parent[jsonKeyPathString] = jsonValue;
    }
    else
    {
        NSInteger count = jsonKeyPathArray.count;
        int i = 0;
        for (; i < count - 1; i++)
        {
            NSMutableDictionary *child = parent[jsonKeyPathArray[i]];
            if (!child)
            {
                child = [NSMutableDictionary dictionary];
                parent[jsonKeyPathArray[i]] = child;
                parent = child;
            }
        }
        parent[jsonKeyPathArray[i]] = jsonValue;
    }
}

static void oo_merge_model_to_model_apply(const void *_value, void *_context)
{
    OOModelContext *context = _context;
    __unsafe_unretained id targetModel = (__bridge id) context->model;
    __unsafe_unretained id sourceModel = (__bridge id) context->storage;
    __unsafe_unretained OOPropertyInfo *propertyInfo = (__bridge id) _value;
    id targetValue = oo_get_value_for_property(targetModel, propertyInfo);
    id sourceValue = oo_get_value_for_property(sourceModel, propertyInfo);
    if (targetValue != sourceValue)
    {
        oo_set_value_for_property(targetModel, sourceValue, propertyInfo);
    }
}

static inline id oo_db_value_from_value(__unsafe_unretained OOPropertyInfo *propertyInfo, __unsafe_unretained id value)
{
    OOEncodingType encodingType = propertyInfo.encodingType;
    if (encodingType & OOEncodingTypeObject)
    {
        switch (encodingType)
        {
            case OOEncodingTypeNSString:

            case OOEncodingTypeNSNumber:

            case OOEncodingTypeNSData:
                return value;
                break;
            case OOEncodingTypeNSURL:
                return [value absoluteString];
                break;
            case OOEncodingTypeNSDate:
                return @([value timeIntervalSince1970]);
                break;
            default:

                break;
        }
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        return value;
    }
    return nil;
}
static inline void oo_stmt_from_unique_property(__unsafe_unretained OOPropertyInfo *propertyInfo,__unsafe_unretained id value,sqlite3_stmt *stmt,int idx){
    OOEncodingType encodingType = propertyInfo.encodingType;
    if (encodingType&OOEncodingTypeObject) {
        switch (encodingType)
        {
            case OOEncodingTypeNSString:
            {
                sqlite3_bind_text(stmt, idx, [value UTF8String], -1, SQLITE_STATIC);
                return;
            }
            case OOEncodingTypeNSNumber:
            {
                sqlite3_bind_text(stmt, idx, [[NSString stringWithFormat:@"%@",value] UTF8String], -1, SQLITE_STATIC);
                return;
            }
            case OOEncodingTypeNSURL:
            {
                sqlite3_bind_text(stmt, idx, [[value absoluteString] UTF8String], -1, SQLITE_STATIC);
                return;
            }
            case OOEncodingTypeNSDate:
            {
                sqlite3_bind_double(stmt, idx, [value timeIntervalSince1970]);
                return;
            }
            case OOEncodingTypeNSData:
            {
                sqlite3_bind_blob(stmt, idx, [value bytes], (int) [value length], SQLITE_STATIC);
            }
                return;
            case OOEncodingTypeOtherObject:
            {
                NSLog(@"unique fetch error---class:%@,property:%@",NSStringFromClass(propertyInfo.ownClassInfo),propertyInfo.propertyKey);
                return;
            }
                break;
            default:
                
                break;
        }
    }else if (encodingType&OOEncodingTypeCType) {
        if (encodingType==OOEncodingTypeUInt64) {
            long long v;
            unsigned long long src=[value unsignedLongLongValue];
            memcpy(&v, &src,sizeof(long long));
            sqlite3_bind_int64(stmt, idx, v);
        }else{
            sqlite3_bind_int64(stmt, idx, [value longLongValue]);
        }
    }
}
static inline void oo_stmt_from_property(__unsafe_unretained OOPropertyInfo *propertyInfo, __unsafe_unretained id model, sqlite3_stmt *stmt, int idx)
{
    OOEncodingType encodingType = propertyInfo.encodingType;
    if (encodingType & OOEncodingTypeObject)
    {
        switch (encodingType)
        {
            case OOEncodingTypeNSString:
            {
                NSString *value = ((NSString * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter);
                sqlite3_bind_text(stmt, idx, [value UTF8String], -1, SQLITE_STATIC);
                return;
            }
            case OOEncodingTypeNSNumber:
            {
                NSString *value = [NSString stringWithFormat:@"%@", ((NSNumber * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter)];
                sqlite3_bind_text(stmt, idx, [value UTF8String], -1, SQLITE_STATIC);
                return;
            }
            case OOEncodingTypeNSURL:
            {
                NSString *value = [((NSURL * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter) absoluteString];
                sqlite3_bind_text(stmt, idx, [value UTF8String], -1, SQLITE_STATIC);
                return;
            }
            case OOEncodingTypeNSDate:
            {
                NSTimeInterval value = [((NSDate * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter) timeIntervalSince1970];
                sqlite3_bind_double(stmt, idx, value);
                return;
            }
            case OOEncodingTypeNSData:
            {
                NSData *value = ((NSData * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter);
                sqlite3_bind_blob(stmt, idx, [value bytes], (int) [value length], SQLITE_STATIC);
            }
                return;
            case OOEncodingTypeOtherObject:
            {
                OOClassInfo *propertyClassInfo = [propertyInfo.propertyCls oo_classInfo];
                if (propertyClassInfo.uniquePropertyKey)
                {
                    oo_stmt_from_property(propertyClassInfo.propertyInfosByPropertyKeys[propertyClassInfo.uniquePropertyKey], ((id (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter), stmt, idx);
                    return;
                }
            }
            break;
            default:

                break;
        }
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        switch (encodingType)
        {
            case OOEncodingTypeBool:
                sqlite3_bind_int64(stmt, idx, (long long) ((bool (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeInt8:
                sqlite3_bind_int64(stmt, idx, (long long) ((char (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeUInt8:
                sqlite3_bind_int64(stmt, idx, (long long) ((unsigned char (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeInt16:
                sqlite3_bind_int64(stmt, idx, (long long) ((short (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeUInt16:
                sqlite3_bind_int64(stmt, idx, (long long) ((UInt16 (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeInt32:
                sqlite3_bind_int64(stmt, idx, (long long) ((int (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeUInt32:
                sqlite3_bind_int64(stmt, idx, (long long) ((UInt32 (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeInt64:
                sqlite3_bind_int64(stmt, idx, ((long long (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeUInt64:
            {
                unsigned long long v=((unsigned long long (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter);
                long long dst;
                memcpy(&dst, &v, sizeof(long long));
                sqlite3_bind_int64(stmt, idx, dst);
            }
                return;
            case OOEncodingTypeFloat:
                sqlite3_bind_double(stmt, idx, (double) ((float (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeDouble:
                sqlite3_bind_double(stmt, idx, ((double (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            default:
                break;
        }
    }
    NSValueTransformer *valueTransformer = propertyInfo.dbValueTransformer;
    if (valueTransformer)
    {
        id transformedValue = [valueTransformer reverseTransformedValue:((id (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter)];
        switch (propertyInfo.dbColumnType)
        {
            case OODbColumnTypeInteger:
                sqlite3_bind_int64(stmt, idx, [transformedValue longLongValue]);
                return;
            case OODbColumnTypeReal:
                sqlite3_bind_double(stmt, idx, [transformedValue doubleValue]);
                return;
            case OODbColumnTypeText:
                sqlite3_bind_text(stmt, idx, [[transformedValue description] UTF8String], -1, SQLITE_STATIC);
                return;
            case OODbColumnTypeBlob:
                sqlite3_bind_blob(stmt, idx, [transformedValue bytes], (int) [transformedValue length], SQLITE_STATIC);
                return;
            default:
                break;
        }
        return;
    }
    NSLog(@"invalid model value for db---class:%@,property:%@", NSStringFromClass(propertyInfo.ownClassInfo.cls), propertyInfo.propertyKey);
}

//static inline void oo_value_from_stmt(__unsafe_unretained OOPropertyInfo *propertyInfo, __unsafe_unretained id model, sqlite3_stmt *stmt, int idx)
//{
//}

static id oo_model_from_unique_value(__unsafe_unretained OOClassInfo *classInfo, __unsafe_unretained id value)
{
    if (classInfo.uniquePropertyKey)
    {
        OOPropertyInfo *propertyInfo = classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
        if (propertyInfo.encodingType != OOEncodingTypeOtherObject)
        {
            return [classInfo.cls oo_modelWithUniqueValue:value];
        }
        else
        {
            return [classInfo.cls oo_modelWithUniqueValue:oo_model_from_unique_value([propertyInfo.propertyCls oo_classInfo], value)];
        }
    }
    return nil;
}

static inline void oo_model_value_from_stmt(__unsafe_unretained OOPropertyInfo *propertyInfo, __unsafe_unretained id model, sqlite3_stmt *stmt, int idx)
{
    NSCParameterAssert(propertyInfo.dbColumnType);
    int type = sqlite3_column_type(stmt, idx);
    OOEncodingType encodingType = propertyInfo.encodingType;
    if (encodingType & OOEncodingTypeObject)
    {
        switch (encodingType)
        {
            case OOEncodingTypeNSString:
                if (type == SQLITE_TEXT)
                {
                    NSString *value = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, idx)];
                    ((void (*)(id, SEL, NSString *))(void *) objc_msgSend)(model, propertyInfo.setter, value);
                }
                return;
            case OOEncodingTypeNSNumber:
                if (type == SQLITE_TEXT)
                {
                    NSString *value = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, idx)];
                    ((void (*)(id, SEL, NSNumber *))(void *) objc_msgSend)(model, propertyInfo.setter, @([value doubleValue]));
                }
                return;
            case OOEncodingTypeNSURL:
                if (type == SQLITE_TEXT)
                {
                    NSString *value = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, idx)];
                    ((void (*)(id, SEL, NSURL *))(void *) objc_msgSend)(model, propertyInfo.setter, [NSURL URLWithString:value]);
                }
                return;
            case OOEncodingTypeNSDate:
                if (type == SQLITE_FLOAT)
                {
                    double value = sqlite3_column_double(stmt, idx);
                    ((void (*)(id, SEL, NSDate *))(void *) objc_msgSend)(model, propertyInfo.setter, [NSDate dateWithTimeIntervalSince1970:value]);
                }
                return;
            case OOEncodingTypeNSData:
                if (type == SQLITE_BLOB)
                {
                    int length = sqlite3_column_bytes(stmt, idx);
                    const void *value = sqlite3_column_blob(stmt, idx);
                    ((void (*)(id, SEL, NSData *))(void *) objc_msgSend)(model, propertyInfo.setter, [NSData dataWithBytes:value length:length]);
                }
                return;
            case OOEncodingTypeOtherObject:
            {
                id value;
                switch (type)
                {
                    case SQLITE_TEXT:
                        value = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, idx)];
                        break;
                    case SQLITE_INTEGER:
                        value = @(sqlite3_column_int64(stmt, idx));
                        break;
                    case SQLITE_FLOAT:
                        value = @(sqlite3_column_double(stmt, idx));
                        break;
                    case SQLITE_BLOB:
                    {
                        int length = sqlite3_column_bytes(stmt, idx);
                        value = [NSData dataWithBytes:sqlite3_column_blob(stmt, idx) length:length];
                    }
                    break;
                    default:
                        break;
                }
                OOClassInfo *classInfo = [propertyInfo.propertyCls oo_classInfo];
                value = oo_model_from_unique_value(classInfo, value);
                ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, propertyInfo.setter, value);
                return;
            }
            default:
                break;
        }
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        switch (encodingType)
        {
            case OOEncodingTypeBool:
                if (type == SQLITE_INTEGER)
                {
                    long long value = sqlite3_column_int64(stmt, idx);
                    ((void (*)(id, SEL, bool))(void *) objc_msgSend)(model, propertyInfo.setter, (bool) value);
                }
                return;
            case OOEncodingTypeInt8:
                if (type == SQLITE_INTEGER)
                {
                    long long value = sqlite3_column_int64(stmt, idx);
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, propertyInfo.setter, (char) value);
                }
                return;
            case OOEncodingTypeUInt8:
                if (type == SQLITE_INTEGER)
                {
                    long long value = sqlite3_column_int64(stmt, idx);
                    ((void (*)(id, SEL, unsigned char))(void *) objc_msgSend)(model, propertyInfo.setter, (unsigned char) value);
                }
                return;
            case OOEncodingTypeInt16:
                if (type == SQLITE_INTEGER)
                {
                    long long value = sqlite3_column_int64(stmt, idx);
                    ((void (*)(id, SEL, short))(void *) objc_msgSend)(model, propertyInfo.setter, (short) value);
                }
                return;
            case OOEncodingTypeUInt16:
                if (type == SQLITE_INTEGER)
                {
                    long long value = sqlite3_column_int64(stmt, idx);
                    ((void (*)(id, SEL, unsigned short))(void *) objc_msgSend)(model, propertyInfo.setter, (unsigned short) value);
                }
                return;
            case OOEncodingTypeInt32:
                if (type == SQLITE_INTEGER)
                {
                    long long value = sqlite3_column_int64(stmt, idx);
                    ((void (*)(id, SEL, int))(void *) objc_msgSend)(model, propertyInfo.setter, (int) value);
                }
                return;
            case OOEncodingTypeUInt32:
                if (type == SQLITE_INTEGER)
                {
                    long long value = sqlite3_column_int64(stmt, idx);
                    ((void (*)(id, SEL, unsigned int))(void *) objc_msgSend)(model, propertyInfo.setter, (unsigned int) value);
                }
                return;
            case OOEncodingTypeInt64:
                if (type == SQLITE_INTEGER)
                {
                    long long value = sqlite3_column_int64(stmt, idx);
                    ((void (*)(id, SEL, long long))(void *) objc_msgSend)(model, propertyInfo.setter, value);
                }
                return;
            case OOEncodingTypeUInt64:
                if (type == SQLITE_INTEGER)
                {
                    long long value = sqlite3_column_int64(stmt, idx);
                    unsigned long long v;
                    memcpy(&v, &value, sizeof(unsigned long long));
                    ((void (*)(id, SEL, unsigned long long))(void *) objc_msgSend)(model, propertyInfo.setter, v);
                }
                return;
            case OOEncodingTypeFloat:
                if (type == SQLITE_FLOAT)
                {
                    double value = sqlite3_column_double(stmt, idx);
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, propertyInfo.setter, (float) value);
                }
                return;
            case OOEncodingTypeDouble:
                if (type == SQLITE_FLOAT)
                {
                    double value = sqlite3_column_double(stmt, idx);
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, propertyInfo.setter, value);
                }
                return;
            default:
                break;
        }
    }
    NSValueTransformer *valueTransformer = propertyInfo.dbValueTransformer;
    if (valueTransformer)
    {
        id value;
        switch (type)
        {
            case SQLITE_INTEGER:
                value = @(sqlite3_column_int64(stmt, idx));
                break;
            case SQLITE_TEXT:
                value = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, idx)];
                break;
            case SQLITE_FLOAT:
                value = @(sqlite3_column_double(stmt, idx));
                break;
            case SQLITE_BLOB:
            {
                int length = sqlite3_column_bytes(stmt, idx);
                value = [NSData dataWithBytes:sqlite3_column_blob(stmt, idx) length:length];
            }
            break;
            default:
                break;
        }
        value = [valueTransformer transformedValue:value];
        ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, propertyInfo.setter, value);
    }
    else
    {
        NSLog(@"----------------class:%@,property:%@", NSStringFromClass(propertyInfo.propertyCls), propertyInfo.propertyKey);
    }
}

static inline bool oo_model_from_stmt(__unsafe_unretained OOClassInfo *classInfo, __unsafe_unretained id model, sqlite3_stmt *stmt)
{
    int count = sqlite3_column_count(stmt);
    bool result = NO;
    for (int i = 0; i < count;)
    {
        i++;
        const char *columnName=sqlite3_column_name(stmt, i);
        if(columnName){
            NSString *propertyKey=[NSString stringWithUTF8String:sqlite3_column_name(stmt, i)];
            OOPropertyInfo *propertyInfo = classInfo.propertyInfosByPropertyKeys[propertyKey];
            if ([classInfo.dbPropertyInfos containsObject:propertyInfo])
            {
                result = YES;
                oo_model_value_from_stmt(propertyInfo, model, stmt, i);
            }
        }
    }
    return result;
}

@implementation NSObject (OOModel)

+ (NSArray *)oo_modelsWithJsonDictionaries:(NSArray *)jsonDictionaries
{
    if (!jsonDictionaries)
    {
        return nil;
    }
    OOClassInfo *classInfo = [self oo_classInfo];
    OOMapTable *mt = classInfo.mapTable;
    OODb *db = classInfo.database;
    __block NSArray *models = nil;
    if (db)
    {
        [db syncInDb:^(OODb *db) {
            models = [self _oo_modelsWithJsonDictionaries:jsonDictionaries classInfo:classInfo mt:mt db:db];
        }];
    }
    else
    {
        models = [self _oo_modelsWithJsonDictionaries:jsonDictionaries classInfo:classInfo mt:mt db:db];
    }
    return models;
}

+ (id)oo_modelWithJsonDictionary:(NSDictionary *)jsonDictionary
{
    if (!jsonDictionary)
    {
        return nil;
    }
    return [self oo_modelsWithJsonDictionaries:@[jsonDictionary]];
}

+ (instancetype)oo_modelWithUniqueValue:(id)uniqueValue
{
    return nil;
}

- (void)oo_mergeWithJsonDictionary:(NSDictionary *)jsonDictionary
{
    OOClassInfo *classInfo = [self.class oo_classInfo];
    [self oo_mergeWithJsonDictionary:jsonDictionary classInfo:classInfo];
}

+ (id)oo_newModelWithJonDictionry:(NSDictionary *)jsonDictionary classInfo:(OOClassInfo *)classInfo
{
    id model = [[self alloc] init];
    [model oo_mergeWithJsonDictionary:jsonDictionary classInfo:classInfo];
    return model;
}

+ (NSArray *)_oo_modelsWithJsonDictionaries:(NSArray *)jsonDictionaries classInfo:(OOClassInfo *)classInfo mt:(OOMapTable *)mt db:(OODb *)db
{
    NSUInteger count = jsonDictionaries.count;
    if (count > 1)
    {
        [db beginTransaction];
    }
    NSMutableArray *models = [NSMutableArray array];
    [jsonDictionaries enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        id model = [self oo_modelWithJonDictionry:obj classInfo:classInfo mt:mt db:db];
        if (model)
        {
            [models addObject:model];
        }
    }];
    if (count > 1)
    {
        [db commit];
    }
    return models.count ? models : nil;
}

+ (id)oo_modelWithJonDictionry:(NSDictionary *)jsonDictionary classInfo:(OOClassInfo *)classInfo mt:(OOMapTable *)mt db:(OODb *)db
{
    __block id model = nil;
    if (!mt)
    {
        model = [self oo_newModelWithJonDictionry:jsonDictionary classInfo:classInfo];
        if (db)
        {
            [self oo_insert:model classInfo:classInfo db:db];
        }
        return model;
    }
    id uniqueValue = [self _oo_uniqueValueInJsonDictionary:jsonDictionary classInfo:classInfo];
    if (!uniqueValue)
    {
        NSLog(@"unique model has no unique value---class:%@,uniqueKey:%@", NSStringFromClass(classInfo.cls), classInfo.uniquePropertyKey);
        return nil;
    }
    [mt syncInMt:^(OOMapTable *mt) {
        model = [mt objectForKey:uniqueValue];
    }];
    if (model)
    {
        [model oo_setIsReplaced:YES];
        [model oo_mergeWithJsonDictionary:jsonDictionary classInfo:classInfo];
        if (db)
        {
            [self oo_update:model classInfo:classInfo db:db];
        }
        return model;
    }
    if (db)
    {
        [db syncInDb:^(OODb *db) {
            [db executeQuery:classInfo.uniqueSelectSql context:(__bridge void *) self stmtBlock:^(void *context, sqlite3_stmt *stmt, int index) {
                OOPropertyInfo *propertyInfo = classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
                oo_stmt_from_unique_property(propertyInfo,uniqueValue,stmt,index);
            }
                resultBlock:^(void *context, sqlite3_stmt *stmt, bool *stop) {
                    model = [[self alloc] init];
                    if (!oo_model_from_stmt(classInfo, model, stmt))
                    {
                        model = nil;
                    }
                    *stop = YES;
                }];
        }];
        [mt syncInMt:^(OOMapTable *mt) {
            id mtModel = [mt objectForKey:uniqueValue];
            if (mtModel)
            {
                model = mtModel;
            }
            else
            {
                if (model)
                {
                    [mt setObject:model forKey:uniqueValue];
                }
            }
        }];
        if (model)
        {
            [model oo_setIsReplaced:YES];
            [model oo_mergeWithJsonDictionary:jsonDictionary classInfo:classInfo];
            [self oo_update:model classInfo:classInfo db:db];
        }
        else
        {
            model = [self oo_newModelWithJonDictionry:jsonDictionary classInfo:classInfo];
            [self oo_insert:model classInfo:classInfo db:db];
        }
    }
    else
    {
        [mt syncInMt:^(OOMapTable *mt) {
            id mtModel = [mt objectForKey:uniqueValue];
            if (mtModel)
            {
                model = mtModel;
            }
            else
            {
                model = [self oo_newModelWithJonDictionry:jsonDictionary classInfo:classInfo];
                [mt setObject:model forKey:uniqueValue];
            }
        }];
    }
    return model;
}

+ (void)oo_insert:(id)model classInfo:(OOClassInfo *)classInfo db:(OODb *)db
{
    [db syncInDb:^(OODb *db) {
        [db executeUpdate:classInfo.insertSql context:(__bridge void *) model stmtBlock:^(void *context, sqlite3_stmt *stmt, int index) {
            OOPropertyInfo *propertyInfo=classInfo.dbPropertyInfos[index-1];
                oo_stmt_from_property(propertyInfo, model, stmt, (int) index);
        }];
    }];
}

+ (void)oo_update:(id)model classInfo:(OOClassInfo *)classInfo db:(OODb *)db
{
    [db syncInDb:^(OODb *db) {
        [db executeUpdate:classInfo.updateSql context:(__bridge void *) model stmtBlock:^(void *context, sqlite3_stmt *stmt, int index) {
            if (index-1==classInfo.dbPropertyInfos.count) {
                oo_stmt_from_property(classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey], model, stmt, (int) index);
            }else{
                OOPropertyInfo *propertyInfo=classInfo.dbPropertyInfos[index-1];
                oo_stmt_from_property(propertyInfo, model, stmt, (int) index);
            }
        }];
    }];
}

- (void)oo_mergeWithJsonDictionary:(NSDictionary *)jsonDictionary classInfo:(OOClassInfo *)classInfo
{
    OOModelContext context = {0};
    context.model = (__bridge void *) self;
    context.storage = (__bridge void *) jsonDictionary;
    CFArrayRef propertyInfos = (__bridge CFArrayRef) classInfo.jsonPropertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_transform_json_dictionary_to_model_apply, &context);
}

- (void)oo_mergerWithModel:(id)model classInfo:(OOClassInfo *)classInfo
{
    OOModelContext context = {0};
    context.model = (__bridge void *) self;
    context.storage = (__bridge void *) model;
    CFArrayRef propertyInfos = (__bridge CFArrayRef) classInfo.propertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_merge_model_to_model_apply, &context);
}

+ (id)_oo_uniqueValueInJsonDictionary:(NSDictionary *)jsonDictionary classInfo:(OOClassInfo *)classInfo
{
    OOPropertyInfo *propertyInfo = nil;
    NSString *uniqueKey = classInfo.uniquePropertyKey;
    id value = nil;
    if (uniqueKey)
    {
        propertyInfo = classInfo.propertyInfosByPropertyKeys[uniqueKey];
        NSString *jsonKeyPath = propertyInfo.jsonKeyPathInString;
        if (jsonKeyPath)
        {
            value = jsonDictionary[jsonKeyPath];
        }
    }
    if (!value)
    {
        return value;
    }
    if (propertyInfo.encodingType == OOEncodingTypeOtherObject)
    {
        value = [self _oo_uniqueValueInJsonDictionary:value classInfo:[propertyInfo.propertyCls oo_classInfo]];
    }
    else
    {
        value = oo_value_from_json_value(value, propertyInfo);
    }
    return value;
}

- (void)oo_setIsReplaced:(bool)isReplaced
{
    if (isReplaced != [self oo_isReplaced])
    {
        objc_setAssociatedObject(self, @selector(oo_isReplaced), @(isReplaced), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (bool)oo_isReplaced
{
    return [objc_getAssociatedObject(self, @selector(oo_isReplaced)) boolValue];
}

- (NSDictionary *)oo_dictionary
{
    OOClassInfo *classInfo = [self.class oo_classInfo];
    OOModelContext context = {0};
    context.model = (__bridge void *) self;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    context.storage = (__bridge void *) dictionary;
    CFArrayRef propertyInfos = (__bridge CFArrayRef) classInfo.jsonPropertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_transform_model_to_dictionary_apply, &context);
    return dictionary;
}

- (NSDictionary *)oo_jsonDictionary
{
    OOClassInfo *classInfo = [self.class oo_classInfo];
    OOModelContext context = {0};
    context.model = (__bridge void *) self;
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionary];
    context.storage = (__bridge void *) jsonDictionary;
    CFArrayRef propertyInfos = (__bridge CFArrayRef) classInfo.jsonPropertyInfos;
    CFArrayApplyFunction(propertyInfos, CFRangeMake(0, CFArrayGetCount(propertyInfos)), oo_transform_model_to_json_dictionary_apply, &context);
    return jsonDictionary;
}

- (NSString *)oo_jsonString
{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[self oo_jsonDictionary] options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
}

+ (OOClassInfo *)oo_classInfo
{
    CFMutableDictionaryRef classInfoRoot = [self oo_classInfos];
    static OSSpinLock lock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&lock);
    OOClassInfo *classInfo = CFDictionaryGetValue(classInfoRoot, (__bridge void *) self);
    if (!classInfo)
    {
        classInfo = [[OOClassInfo alloc] initWithClass:self];
        [self oo_setDb:oo_global_db classInfo:classInfo];
        CFDictionarySetValue(classInfoRoot, (__bridge void *) self, (__bridge void *) classInfo);
    }
    OSSpinLockUnlock(&lock);
    return classInfo;
}

+ (CFMutableDictionaryRef)oo_classInfos
{
    static CFMutableDictionaryRef oo_classInfos = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        oo_classInfos = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    });
    return oo_classInfos;
}

+ (void)oo_setDb:(OODb *)db classInfo:(OOClassInfo*)classInfo{
    if (classInfo.database!=db) {
        classInfo.database=db;
        [self oo_createDb:classInfo db:db];
    }
}

+ (void)oo_setDb:(OODb *)db
{
    OOClassInfo *classInfo=[self oo_classInfo];
    [self oo_setDb:db classInfo:classInfo];
//    static OSSpinLock lock=OS_SPINLOCK_INIT;
//    OSSpinLockLock(lock);

//    OSSpinLockUnlock(lock);
}

+ (void)oo_setGlobalDb:(OODb*)db{
//    static OSSpinLock lock=OS_SPINLOCK_INIT;
//    OSSpinLockLock(lock);
    if (oo_global_db!=db) {
        oo_global_db=db;
        [(__bridge NSDictionary*)[self oo_classInfos] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, OOClassInfo *  _Nonnull classInfo, BOOL * _Nonnull stop) {
            [classInfo.cls oo_setDb:oo_global_db classInfo:classInfo];
        }];
    }
//    OSSpinLockUnlock(lock);
}

+ (void)oo_createDb:(OOClassInfo*)classInfo db:(OODb*)db
{
    [self oo_createTable:classInfo db:db];
    [self oo_addColumn:classInfo db:db];
    [self oo_addIndexes:classInfo db:db];
}

+ (void)oo_deleteModelsBeforeDate:(NSDate*)date{
    OOClassInfo *classInfo=[self oo_classInfo];
    OODb *db=classInfo.database;
    [self oo_deleteModelsBeforeDate:date classInfo:classInfo db:db];
}

+ (void)oo_deleteModelsBeforeDate:(NSDate*)date classInfo:(OOClassInfo*)classInfo db:(OODb*)db{
    NSString *sql=[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@<%f",classInfo.database,oo_latest_used_timestamp,[date timeIntervalSince1970]];
    [db executeUpdate:sql arguments:nil];
}

#pragma mark --
#pragma mark -- check func

+ (void)oo_createTable:(OOClassInfo*)classInfo db:(OODb*)db{
    NSString * table=classInfo.dbTableName;
    if (![self oo_checkTable:table db:db]) {
        NSString *sql;
        if ([self conformsToProtocol:@protocol(OOUniqueModel)]) {
            NSString *uniquePropertyKey=[self.class uniquePropertyKey];
            OOPropertyInfo *propertyInfo=classInfo.propertyInfosByPropertyKeys[uniquePropertyKey];
            NSString *uniqueDbColumn=propertyInfo.propertyKey;
            NSString * uniqueDbColumnType=oo_databaseColumnTypeWithType(propertyInfo.dbColumnType);
            sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'%@' %@ NOT NULL UNIQUE,'%@' REAL)",table,uniqueDbColumn,uniqueDbColumnType,oo_latest_used_timestamp];
        }else{
            sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'%@' REAL)",table,oo_latest_used_timestamp];
        }
        [db executeUpdate:sql arguments:nil];
    }
}

+ (void)oo_addColumn:(OOClassInfo*)classInfo db:(OODb*)db{
    NSString * table=classInfo.dbTableName;
    [classInfo.dbPropertyInfos enumerateObjectsUsingBlock:^(OOPropertyInfo * _Nonnull propertyInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([propertyInfo.propertyKey isEqualToString:classInfo.uniquePropertyKey]) {
            return;
        }
        if (![self oo_checkTable:table column:propertyInfo.propertyKey db:db]) {
            NSString *dbColumnType=oo_databaseColumnTypeWithType(propertyInfo.dbColumnType);
            NSString *sql=[NSString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN '%@' %@",table,propertyInfo.propertyKey,dbColumnType];
            [db executeUpdate:sql arguments:nil];
        }
    }];
}

+ (void)oo_addIndexes:(OOClassInfo*)classInfo db:(OODb*)db{
    NSMutableArray *databaseIndexesKeys=[NSMutableArray array];
    if ([self respondsToSelector:@selector(dbIndexesInPropertyKeys)]) {
        NSArray *indexesKeys=[self.class dbIndexesInPropertyKeys];
        [indexesKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull propertyKey, NSUInteger idx, BOOL * _Nonnull stop) {
            NSParameterAssert([propertyKey isKindOfClass:NSString.class]);
            [databaseIndexesKeys addObject:propertyKey];
        }];
    }
    [databaseIndexesKeys addObject:oo_latest_used_timestamp];
    [databaseIndexesKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull databaseIndexKey, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self oo_checkTable:classInfo.dbTableName index:databaseIndexKey db:db]) {
            NSString *index=[NSString stringWithFormat:@"%@_%@_index",classInfo.dbTableName,databaseIndexKey];
            NSString *sql=[NSString stringWithFormat:@"CREATE INDEX %@ on %@(%@)",index,classInfo.dbTableName,databaseIndexKey];
            [db executeUpdate:sql arguments:nil];
        }
    }];
}

+ (BOOL)oo_checkTable:(NSString*)table db:(OODb*)db{
    NSString * sql=@"SELECT * FROM sqlite_master WHERE tbl_name=? AND type='table'";
    NSArray * sets=[db executeQuery:sql arguments:@[table]];
    if (sets.count>0) {
        return YES;
    }else{
        return NO;
    }
}

+ (BOOL)oo_checkTable:(NSString*)table column:(NSString*)column db:(OODb*)db {
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

+ (BOOL)oo_checkTable:(NSString*)table index:(NSString*)index db:(OODb*)db{
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

+ (BOOL)oo_checkTable:(NSString*)table primaryKey:(NSString*)key primaryValue:(id)value db:(OODb*)db{
    NSParameterAssert(value);
    NSString *sql=[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=?",table,key];
    NSArray * sets=[db executeQuery:sql arguments:@[value]];
    if (sets.count>0) {
        return YES;
    }else{
        return NO;
    }
}
@end
