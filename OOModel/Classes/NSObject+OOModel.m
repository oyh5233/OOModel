//
//  NSObject+OOModel.m
//  OOModel
//

#import "NSObject+OOModel.h"
#import "OOModel.h"
#import <libkern/OSAtomic.h>
#import <objc/message.h>

static NSString *oo_update_timestamp = @"oo_update_timestamp";
static OODb *oo_global_db = nil;

typedef struct
{
    void *model;
    void *storage;

} OOModelContext;

static inline NSString *oo_databaseColumnTypeWithType(OODbColumnType type)
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
            NSCAssert(type, @"[unexpected db column type]");
            break;
    }
    return dbColumnType;
}

static inline void oo_set_value_for_property(__unsafe_unretained id model, __unsafe_unretained id value, __unsafe_unretained OOPropertyInfo *propertyInfo)
{
    OOEncodingType encodingType = propertyInfo.encodingType;
    SEL setter = propertyInfo.setter;
    if (encodingType & OOEncodingTypeObject)
    {
        if (value == (id) kCFNull)
        {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, nil);
        }
        else
        {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, value);
        }
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        if (value == nil || value == (id) kCFNull)
        {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)(model, setter, 0);
        }
        else
        {
            switch (encodingType)
            {
                case OOEncodingTypeBool:
                    ((void (*)(id, SEL, bool))(void *) objc_msgSend)(model, setter, [value boolValue]);
                    break;
                case OOEncodingTypeInt8:
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, setter, [value charValue]);
                    break;
                case OOEncodingTypeUInt8:
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, setter, [value unsignedCharValue]);
                    break;
                case OOEncodingTypeInt16:
                    ((void (*)(id, SEL, short))(void *) objc_msgSend)(model, setter, [value shortValue]);
                    break;
                case OOEncodingTypeUInt16:
                    ((void (*)(id, SEL, UInt16))(void *) objc_msgSend)(model, setter, [value unsignedShortValue]);
                    break;
                case OOEncodingTypeInt32:
                    ((void (*)(id, SEL, int))(void *) objc_msgSend)(model, setter, [value intValue]);
                    break;
                case OOEncodingTypeUInt32:
                    ((void (*)(id, SEL, UInt32))(void *) objc_msgSend)(model, setter, [value unsignedIntValue]);
                    break;
                case OOEncodingTypeInt64:
                    ((void (*)(id, SEL, long long))(void *) objc_msgSend)(model, setter, (long long) [value longLongValue]);
                    break;
                case OOEncodingTypeUInt64:
                    ((void (*)(id, SEL, UInt64))(void *) objc_msgSend)(model, setter, [value unsignedLongLongValue]);
                    break;
                case OOEncodingTypeFloat:
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, setter, [value floatValue]);
                    break;
                case OOEncodingTypeDouble:
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, setter, [value doubleValue]);
                    break;
                default:
                    break;
            }
        }
    }
    else
    {
        [model setValue:value forKey:propertyInfo.propertyKey];
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

static inline id oo_unique_value_in_model(__unsafe_unretained id model,__unsafe_unretained OOClassInfo *classInfo){
    __unsafe_unretained OOPropertyInfo *propertyInfo = classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
    id value = oo_get_value_for_property(model, propertyInfo);
    if (!value)
    {
        return value;
    }
    if (propertyInfo.encodingType == OOEncodingTypeOtherObject)
    {
        value = oo_unique_value_in_model(value,[propertyInfo.propertyCls oo_classInfo]);
    }
    return value;
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
                break;
            default:
            {
                OOClassInfo *propertyClassInfo = [propertyInfo.propertyCls oo_classInfo];
                if (propertyClassInfo.jsonPropertyInfos)
                {
                    return [propertyInfo.propertyCls oo_modelWithJsonDictionary:value];
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
        return [valueTransformer transformedValue:value];
    }
    OOMD_LOG(@"[class:%@,propertyKey:%@,json:%@] [json value can not transform to property value]", NSStringFromClass(propertyInfo.ownClassInfo.cls), propertyInfo.propertyKey, value);
    return nil;
}

static inline id oo_json_value_from_value(__unsafe_unretained id value, OOPropertyInfo *propertyInfo)
{
    if (!value)
    {
        return nil;
    }
    OOEncodingType encodingType = propertyInfo.encodingType;
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
                    return [value oo_jsonDictionary];
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
        return [valueTransformer reverseTransformedValue:value];
    }
    OOMD_LOG(@"[class:%@,propertyKey:%@,propertyValue:%@] [property value can not transform to json value]",
             NSStringFromClass(propertyInfo.ownClassInfo.cls),
             propertyInfo.propertyKey, value);
    return nil;
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

static inline id oo_unique_value_in_json_dictionary(__unsafe_unretained NSDictionary *jsonDictionary,__unsafe_unretained OOClassInfo *classInfo){
    __unsafe_unretained OOPropertyInfo *propertyInfo = classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
    id value = jsonDictionary[propertyInfo.jsonKeyPathInString];
    if (!value)
    {
        return value;
    }
    if (propertyInfo.encodingType == OOEncodingTypeOtherObject)
    {
        value = oo_unique_value_in_json_dictionary(value,[propertyInfo.propertyCls oo_classInfo]);
    }
    else
    {
        value = oo_value_from_json_value(value, propertyInfo);
    }
    return value;
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

static inline id oo_model_from_unique_value(__unsafe_unretained OOClassInfo *classInfo, __unsafe_unretained id value)
{
    NSCAssert(classInfo.uniquePropertyKey, @"[class:%@] [class should implement +(NSStrng*)oo_uniquePropertyKey:]", NSStringFromClass(classInfo.cls));
    if (!value)
    {
        return nil;
    }
    OOPropertyInfo *propertyInfo = classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
    if (propertyInfo.encodingType != OOEncodingTypeOtherObject)
    {
        return [classInfo.cls oo_modelWithUniqueValue:value];
    }
    else
    {
        return [classInfo.cls oo_modelWithUniqueValue:oo_model_from_unique_value([propertyInfo.propertyCls oo_classInfo], value)];
    }
    return nil;
}

static inline void oo_model_value_from_stmt(__unsafe_unretained OOPropertyInfo *propertyInfo, __unsafe_unretained id model, sqlite3_stmt *stmt, int idx)
{
    int type = sqlite3_column_type(stmt, idx);
    if (type == SQLITE_NULL)
    {
        return;
    }
    OOEncodingType encodingType = propertyInfo.encodingType;
    if (encodingType & OOEncodingTypeObject)
    {

        switch (encodingType)
        {
            case OOEncodingTypeNSString:
                ((void (*)(id, SEL, NSString *))(void *) objc_msgSend)(
                    model, propertyInfo.setter, [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, idx)]);
                return;
            case OOEncodingTypeNSNumber:
                ((void (*)(id, SEL, NSNumber *))(void *) objc_msgSend)(
                    model, propertyInfo.setter, @([[NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, idx)] doubleValue]));
                return;
            case OOEncodingTypeNSURL:
                ((void (*)(id, SEL, NSURL *))(void *) objc_msgSend)(model, propertyInfo.setter, [NSURL URLWithString:[NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, idx)]]);
                return;
            case OOEncodingTypeNSDate:
                ((void (*)(id, SEL, NSDate *))(void *) objc_msgSend)(model, propertyInfo.setter, [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmt, idx)]);
                return;
            case OOEncodingTypeNSData:
            {
                int length = sqlite3_column_bytes(stmt, idx);
                const void *value = sqlite3_column_blob(stmt, idx);
                ((void (*)(id, SEL, NSData *))(void *) objc_msgSend)(model, propertyInfo.setter, [NSData dataWithBytes:value length:length]);
                return;
            }
            default:
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
                        value = nil;
                        break;
                }
                OOClassInfo *classInfo = [propertyInfo.propertyCls oo_classInfo];
                if (classInfo.uniquePropertyKey)
                {
                    value = oo_model_from_unique_value(classInfo, value);
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, propertyInfo.setter, value);
                    return;
                }
            }
            break;
        }
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        switch (encodingType)
        {
            case OOEncodingTypeBool:
            {
                long long value = sqlite3_column_int64(stmt, idx);
                ((void (*)(id, SEL, bool))(void *) objc_msgSend)(model, propertyInfo.setter, (bool) value);
                return;
            }
            case OOEncodingTypeInt8:
            {
                long long value = sqlite3_column_int64(stmt, idx);
                ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, propertyInfo.setter, (char) value);
                return;
            }
            case OOEncodingTypeUInt8:
            {
                long long value = sqlite3_column_int64(stmt, idx);
                ((void (*)(id, SEL, unsigned char))(void *) objc_msgSend)(model, propertyInfo.setter, (unsigned char) value);
                return;
            }
            case OOEncodingTypeInt16:
            {
                long long value = sqlite3_column_int64(stmt, idx);
                ((void (*)(id, SEL, short))(void *) objc_msgSend)(model, propertyInfo.setter, (short) value);
                return;
            }
            case OOEncodingTypeUInt16:
            {
                long long value = sqlite3_column_int64(stmt, idx);
                ((void (*)(id, SEL, unsigned short))(void *) objc_msgSend)(model, propertyInfo.setter, (unsigned short) value);
                return;
            }
            case OOEncodingTypeInt32:
            {
                long long value = sqlite3_column_int64(stmt, idx);
                ((void (*)(id, SEL, int))(void *) objc_msgSend)(model, propertyInfo.setter, (int) value);
                return;
            }
            case OOEncodingTypeUInt32:
            {
                long long value = sqlite3_column_int64(stmt, idx);
                ((void (*)(id, SEL, unsigned int))(void *) objc_msgSend)(model, propertyInfo.setter, (unsigned int) value);
                return;
            }
            case OOEncodingTypeInt64:
            {
                long long value = sqlite3_column_int64(stmt, idx);
                ((void (*)(id, SEL, long long))(void *) objc_msgSend)(model, propertyInfo.setter, value);
                return;
            }
            case OOEncodingTypeUInt64:
            {
                long long value = sqlite3_column_int64(stmt, idx);
                unsigned long long v;
                memcpy(&v, &value, sizeof(unsigned long long));
                ((void (*)(id, SEL, unsigned long long))(void *) objc_msgSend)(model, propertyInfo.setter, v);
                return;
            }
            case OOEncodingTypeFloat:
            {
                double value = sqlite3_column_double(stmt, idx);
                ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, propertyInfo.setter, (float) value);
                return;
            }
            case OOEncodingTypeDouble:
            {
                double value = sqlite3_column_double(stmt, idx);
                ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, propertyInfo.setter, value);
                return;
            }
            default:
                break;
        }
    }
    __unsafe_unretained NSValueTransformer *valueTransformer = propertyInfo.dbValueTransformer;
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
                value = nil;
                break;
        }
        ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, propertyInfo.setter, [valueTransformer transformedValue:value]);
    }
    else
    {
        OOMD_LOG(@"[class:%@,propertyKey:%@] [db value can not transform to property value]", NSStringFromClass(propertyInfo.propertyCls), propertyInfo.propertyKey);
    }
}

static inline bool oo_model_from_stmt(__unsafe_unretained OOClassInfo *classInfo, __unsafe_unretained id model, sqlite3_stmt *stmt)
{
    int count = sqlite3_column_count(stmt);
    bool result = NO;
    for (int i = 0; i < count;)
    {
        i++;
        const char *columnName = sqlite3_column_name(stmt, i);
        if (columnName)
        {
            NSString *propertyKey = [NSString stringWithUTF8String:sqlite3_column_name(stmt, i)];
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

static inline void oo_bind_stmt_from_value(__unsafe_unretained OOPropertyInfo *propertyInfo, __unsafe_unretained id value, sqlite3_stmt *stmt, int idx)
{
    if (!value)
    {
        sqlite3_bind_null(stmt, idx);
        return;
    }
    OOEncodingType encodingType = propertyInfo.encodingType;
    if (encodingType & OOEncodingTypeObject)
    {
        switch (encodingType)
        {
            case OOEncodingTypeNSString:
            {
                sqlite3_bind_text(stmt, idx, [value UTF8String], -1, SQLITE_STATIC);
                return;
            }
            case OOEncodingTypeNSNumber:
            {
                sqlite3_bind_text(stmt, idx, [[NSString stringWithFormat:@"%@", value] UTF8String], -1, SQLITE_STATIC);
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
            default:
            {
                OOClassInfo *classInfo = [propertyInfo.propertyCls oo_classInfo];
                if (classInfo.uniquePropertyKey)
                {
                    oo_bind_stmt_from_value(classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey], value, stmt, idx);
                    return;
                }
            }
            break;
        }
    }
    else if (encodingType & OOEncodingTypeCType)
    {
        if (encodingType == OOEncodingTypeUInt64)
        {
            long long dst;
            unsigned long long src = [value unsignedLongLongValue];
            memcpy(&dst, &src, sizeof(long long));
            sqlite3_bind_int64(stmt, idx, dst);
        }
        else
        {
            sqlite3_bind_int64(stmt, idx, [value longLongValue]);
        }
        return;
    }
    __unsafe_unretained NSValueTransformer *valueTransformer = propertyInfo.dbValueTransformer;
    if (valueTransformer)
    {
        id transformedValue = [valueTransformer reverseTransformedValue:value];
        if (!transformedValue)
        {
            sqlite3_bind_null(stmt, idx);
        }
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
                NSCAssert(@"[class:%@,propertyKey:%@] [property should implement +(OODbColumnType)oo_dbColumnTypeForPropertyKey:]", NSStringFromClass(propertyInfo.ownClassInfo.cls), propertyInfo.propertyKey);
                break;
        }
    }
    else
    {
        NSCAssert(@"[class:%@,propertyKey:%@,propertyValue:%@] [can not bind value to stmt]", NSStringFromClass(propertyInfo.ownClassInfo.cls), propertyInfo.propertyKey, value);
    }
}
static inline void oo_bind_stmt_from_model(__unsafe_unretained OOPropertyInfo *propertyInfo, __unsafe_unretained id model, sqlite3_stmt *stmt, int idx)
{
    OOEncodingType encodingType = propertyInfo.encodingType;
    if (encodingType & OOEncodingTypeObject)
    {
        switch (encodingType)
        {
            case OOEncodingTypeNSString:
                sqlite3_bind_text(stmt, idx, [((NSString * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter) UTF8String], -1, SQLITE_STATIC);
                return;
            case OOEncodingTypeNSNumber:
                sqlite3_bind_text(stmt, idx, [[NSString stringWithFormat:@"%@", ((NSNumber * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter)] UTF8String], -1, SQLITE_STATIC);
                return;
            case OOEncodingTypeNSURL:
                sqlite3_bind_text(stmt, idx, [[((NSURL * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter) absoluteString] UTF8String], -1, SQLITE_STATIC);
                return;
            case OOEncodingTypeNSDate:
                sqlite3_bind_double(stmt, idx, [((NSDate * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter) timeIntervalSince1970]);
                return;
            case OOEncodingTypeNSData:
            {
                NSData *value = ((NSData * (*) (id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter);
                sqlite3_bind_blob(stmt, idx, [value bytes], (int) [value length], SQLITE_STATIC);
            }
                return;
            default:
            {
                OOClassInfo *propertyClassInfo = [propertyInfo.propertyCls oo_classInfo];
                if (propertyClassInfo.uniquePropertyKey)
                {
                    oo_bind_stmt_from_model(propertyClassInfo.propertyInfosByPropertyKeys[propertyClassInfo.uniquePropertyKey], ((id (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter), stmt, idx);
                    return;
                }
            }
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
                sqlite3_bind_int64(stmt, idx,
                                   (long long) ((char (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeUInt8:
                sqlite3_bind_int64(stmt, idx,
                                   (long long) ((unsigned char (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeInt16:
                sqlite3_bind_int64(stmt, idx,
                                   (long long) ((short (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeUInt16:
                sqlite3_bind_int64(stmt, idx,
                                   (long long) ((UInt16 (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeInt32:
                sqlite3_bind_int64(stmt, idx,
                                   (long long) ((int (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeUInt32:
                sqlite3_bind_int64(stmt, idx,
                                   (long long) ((UInt32 (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeInt64:
                sqlite3_bind_int64(stmt, idx,
                                   ((long long (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter));
                return;
            case OOEncodingTypeUInt64:
            {
                unsigned long long v = ((unsigned long long (*)(id, SEL))(void *) objc_msgSend)(model, propertyInfo.getter);
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
    __unsafe_unretained NSValueTransformer *valueTransformer = propertyInfo.dbValueTransformer;
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
                NSCAssert(@"[class:%@,propertyKey:%@] [property should implement +(OODbColumnType)oo_dbColumnTypeForPropertyKey:]", NSStringFromClass(propertyInfo.ownClassInfo.cls), propertyInfo.propertyKey);
                break;
        }
    }
    else
    {
        NSCAssert(@"[class:%@,propertyKey:%@] [can not bind value to stmt]", NSStringFromClass(propertyInfo.ownClassInfo.cls), propertyInfo.propertyKey);
    }
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

+ (NSArray *)oo_modelsWithAfterWhereSql:(NSString *)afterWhereSql arguments:(NSArray *)arguments
{
    OOClassInfo *classInfo = [self oo_classInfo];
    OODb *db = classInfo.database;
    OOMapTable *mt =classInfo.mapTable;
    NSMutableArray *array = [NSMutableArray array];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@", classInfo.dbTableName];
    if (afterWhereSql)
    {
        sql = [sql stringByAppendingFormat:@" WHERE %@", afterWhereSql];
    }
    [db syncInDb:^(OODb *db) {
        [db executeQuery:sql arguments:arguments resultBlock:^(sqlite3_stmt *stmt, bool *stop) {
            id model = [[self alloc] init];
            if (oo_model_from_stmt(classInfo, model, stmt))
            {
                if (mt) {
                    [mt syncInMt:^(OOMapTable *mt) {
                        id uniqueValue=oo_unique_value_in_model(model, classInfo);
                        id mtModel=[mt objectForKey:uniqueValue];
                        if (mtModel) {
                            [array addObject:mtModel];
                        }else{
                            [mt setObject:model forKey:uniqueValue];
                            [array addObject:model];
                        }
                    }];
                }else{
                    [array addObject:model];
                }
            }
        }];
    }];
    return array.count ? array : nil;
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
    id uniqueValue = oo_unique_value_in_json_dictionary(jsonDictionary, classInfo);
    if (!uniqueValue)
    {
        OOMD_LOG(@"[class:%@,propertyKey:%@] [class do not have a unique value]", NSStringFromClass(classInfo.cls), classInfo.uniquePropertyKey);
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
            [db executeQuery:classInfo.uniqueSelectSql stmtBlock:^(sqlite3_stmt *stmt, int idx) {
                OOPropertyInfo *propertyInfo = classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey];
                oo_bind_stmt_from_value(propertyInfo, uniqueValue, stmt, idx);
            }
                resultBlock:^(sqlite3_stmt *stmt, bool *stop) {
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
        [db executeUpdate:classInfo.insertSql stmtBlock:^(sqlite3_stmt *stmt, int idx) {
            OOPropertyInfo *propertyInfo = classInfo.dbPropertyInfos[idx - 1];
            oo_bind_stmt_from_model(propertyInfo, model, stmt, (int) idx);
        }];
    }];
}

+ (void)oo_update:(id)model classInfo:(OOClassInfo *)classInfo db:(OODb *)db
{
    [db syncInDb:^(OODb *db) {
        [db executeUpdate:classInfo.updateSql stmtBlock:^(sqlite3_stmt *stmt, int idx) {
            if (idx - 1 == classInfo.dbPropertyInfos.count)
            {
                oo_bind_stmt_from_model(classInfo.propertyInfosByPropertyKeys[classInfo.uniquePropertyKey], model, stmt, (int) idx);
            }
            else
            {
                OOPropertyInfo *propertyInfo = classInfo.dbPropertyInfos[idx - 1];
                oo_bind_stmt_from_model(propertyInfo, model, stmt, (int) idx);
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
        classInfo.database = oo_global_db;
        [classInfo.cls oo_createDb:classInfo db:oo_global_db];
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

+ (void)oo_setDb:(OODb *)db forAll:(bool)forAll
{
    @synchronized(NSObject.class)
    {
        if (forAll)
        {
            if (oo_global_db != db)
            {
                oo_global_db = db;
                [(__bridge NSDictionary *) [self oo_classInfos] enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, OOClassInfo *_Nonnull classInfo, BOOL *_Nonnull stop) {
                    if (classInfo.database != db)
                    {
                        classInfo.database = db;
                        [self oo_createDb:classInfo db:db];
                    }
                }];
            }
        }
        else
        {
            OOClassInfo *classInfo = [self oo_classInfo];
            if (classInfo.database != db)
            {
                classInfo.database = db;
                [self oo_createDb:classInfo db:db];
            }
        }
    }
}

+ (void)oo_createDb:(OOClassInfo *)classInfo db:(OODb *)db
{
    [self oo_createTable:classInfo db:db];
    [self oo_addColumn:classInfo db:db];
    [self oo_addIndexes:classInfo db:db];
}

+ (void)oo_deleteModelsBeforeDate:(NSDate *)date
{
    OOClassInfo *classInfo = [self oo_classInfo];
    OODb *db = classInfo.database;
    [self oo_deleteModelsBeforeDate:date classInfo:classInfo db:db];
}

+ (void)oo_deleteModelsBeforeDate:(NSDate *)date classInfo:(OOClassInfo *)classInfo db:(OODb *)db
{
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@<%f", classInfo.database, oo_update_timestamp, [date timeIntervalSince1970]];
    [db executeUpdate:sql arguments:nil];
}

#pragma mark--
#pragma mark-- check func

+ (void)oo_createTable:(OOClassInfo *)classInfo db:(OODb *)db
{
    NSString *table = classInfo.dbTableName;
    if (![self oo_checkTable:table db:db])
    {
        NSString *sql;
        if ([self conformsToProtocol:@protocol(OOUniqueModel)])
        {
            NSString *uniquePropertyKey = [self.class oo_uniquePropertyKey];
            OOPropertyInfo *propertyInfo = classInfo.propertyInfosByPropertyKeys[uniquePropertyKey];
            NSString *uniqueDbColumn = propertyInfo.propertyKey;
            NSString *uniqueDbColumnType = oo_databaseColumnTypeWithType(propertyInfo.dbColumnType);
            sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'%@' %@ NOT NULL UNIQUE,'%@' REAL)", table, uniqueDbColumn, uniqueDbColumnType, oo_update_timestamp];
        }
        else
        {
            sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'%@' REAL)", table, oo_update_timestamp];
        }
        [db executeUpdate:sql arguments:nil];
    }
}

+ (void)oo_addColumn:(OOClassInfo *)classInfo db:(OODb *)db
{
    NSString *table = classInfo.dbTableName;
    [classInfo.dbPropertyInfos enumerateObjectsUsingBlock:^(OOPropertyInfo *_Nonnull propertyInfo, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([propertyInfo.propertyKey isEqualToString:classInfo.uniquePropertyKey])
        {
            return;
        }
        if (![self oo_checkTable:table column:propertyInfo.propertyKey db:db])
        {
            NSString *dbColumnType = oo_databaseColumnTypeWithType(propertyInfo.dbColumnType);
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN '%@' %@", table, propertyInfo.propertyKey, dbColumnType];
            [db executeUpdate:sql arguments:nil];
        }
    }];
}

+ (void)oo_addIndexes:(OOClassInfo *)classInfo db:(OODb *)db
{
    NSMutableArray *databaseIndexesKeys = [NSMutableArray array];
    if ([self respondsToSelector:@selector(oo_dbIndexesInPropertyKeys)])
    {
        NSArray *indexesKeys = [self.class oo_dbIndexesInPropertyKeys];
        [indexesKeys enumerateObjectsUsingBlock:^(NSString *_Nonnull propertyKey, NSUInteger idx, BOOL *_Nonnull stop) {
            NSParameterAssert([propertyKey isKindOfClass:NSString.class]);
            [databaseIndexesKeys addObject:propertyKey];
        }];
    }
    [databaseIndexesKeys addObject:oo_update_timestamp];
    [databaseIndexesKeys enumerateObjectsUsingBlock:^(NSString *_Nonnull databaseIndexKey, NSUInteger idx, BOOL *_Nonnull stop) {
        if (![self oo_checkTable:classInfo.dbTableName index:databaseIndexKey db:db])
        {
            NSString *index = [NSString stringWithFormat:@"%@_%@_index", classInfo.dbTableName, databaseIndexKey];
            NSString *sql = [NSString stringWithFormat:@"CREATE INDEX %@ on %@(%@)", index, classInfo.dbTableName, databaseIndexKey];
            [db executeUpdate:sql arguments:nil];
        }
    }];
}

+ (BOOL)oo_checkTable:(NSString *)table db:(OODb *)db
{
    NSString *sql = @"SELECT * FROM sqlite_master WHERE tbl_name=? AND type='table'";
    NSArray *sets = [db executeQuery:sql arguments:@[table]];
    if (sets.count > 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

+ (BOOL)oo_checkTable:(NSString *)table column:(NSString *)column db:(OODb *)db
{
    BOOL ret = NO;
    NSString *sql =
        @"SELECT * FROM sqlite_master WHERE tbl_name=? AND type='table'";
    NSArray *sets = [db executeQuery:sql arguments:@[table]];
    column = [NSString stringWithFormat:@"'%@'", column];
    if (sets.count > 0)
    {
        for (NSDictionary *set in sets)
        {
            NSString *createSql = set[@"sql"];
            if (createSql &&
                [createSql rangeOfString:column].location != NSNotFound)
            {
                ret = YES;
                break;
            }
        }
    }
    return ret;
}

+ (BOOL)oo_checkTable:(NSString *)table index:(NSString *)index db:(OODb *)db
{
    __block BOOL ret;
    NSString *sql =
        @"SELECT * FROM sqlite_master WHERE tbl_name=? AND type='index'";
    ret = NO;
    NSArray *sets = [db executeQuery:sql arguments:@[table]];
    index = [NSString stringWithFormat:@"(%@)", index];
    if (sets.count > 0)
    {
        for (NSDictionary *set in sets)
        {
            NSString *createSql = set[@"sql"];
            if (createSql && [createSql rangeOfString:index].location != NSNotFound)
            {
                ret = YES;
                break;
            }
        }
    }
    return ret;
}

+ (BOOL)oo_checkTable:(NSString *)table primaryKey:(NSString *)key primaryValue:(id)value db:(OODb *)db
{
    NSParameterAssert(value);
    NSString *sql =
        [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=?", table, key];
    NSArray *sets = [db executeQuery:sql arguments:@[value]];
    if (sets.count > 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}
@end
