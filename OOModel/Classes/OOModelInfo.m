//
//  OOPropertyInfo.m
//  OOModel
//

#import "OOModel.h"
#import "OOModelInfo.h"
static OODb *oo_global_db = nil;

@interface OOClassInfo ()

@property(nonatomic, assign) Class cls;
@property(nonatomic, strong) NSArray *propertyKeys;
@property(nonatomic, strong) NSArray *propertyInfos;
@property(nonatomic, strong) NSDictionary *propertyInfosByPropertyKeys;
@property(nonatomic, strong) NSArray *jsonPropertyInfos;
@property(nonatomic, copy) NSString *uniquePropertyKey;
@property(nonatomic, strong) NSArray *dbPropertyInfos;
@property(nonatomic, copy) NSString *dbTableName;
@property(nonatomic, copy) NSString *uniqueSelectSql;
@property(nonatomic, copy) NSString *insertSql;
@property(nonatomic, copy) NSString *updateSql;

@end

@interface OOPropertyInfo ()

@property(nonatomic, copy) NSString *ivarKey;
@property(nonatomic, copy) NSString *propertyKey;
@property(nonatomic, assign) Class propertyCls;
@property(nonatomic, assign) OOEncodingType encodingType;
@property(nonatomic, assign) OOPropertyType propertyType;
@property(nonatomic, assign) OOReferenceType referenceType;
@property(nonatomic, assign) SEL setter;
@property(nonatomic, assign) SEL getter;
@property(nonatomic, weak) OOClassInfo *ownClassInfo;
@property(nonatomic, strong) NSValueTransformer *jsonValueTransformer;
@property(nonatomic, copy) NSString *jsonKeyPathInString;
@property(nonatomic, strong) NSArray *jsonKeyPathInArray;
@property(nonatomic, strong) NSValueTransformer *dbValueTransformer;
@property(nonatomic, assign) OODbColumnType dbColumnType;
@property(nonatomic, assign) SEL dbForwards;

@end

@implementation OOClassInfo

- (instancetype)initWithClass:(Class)cls
{
    self = [self init];
    if (self)
    {
        self.cls = cls;
        NSMutableDictionary *propertyInfosByPropertyKeys = [NSMutableDictionary dictionary];
        [self enumeratePropertiesUsingBlock:^(objc_property_t property) {
            OOPropertyInfo *propertyInfo = [[OOPropertyInfo alloc] initWithProperty:property];
            propertyInfo.ownClassInfo = self;
            [propertyInfosByPropertyKeys setObject:propertyInfo forKey:propertyInfo.propertyKey];
        }];
        self.propertyInfosByPropertyKeys = propertyInfosByPropertyKeys;
        self.propertyKeys = [self.propertyInfosByPropertyKeys allKeys];
        self.propertyInfos = [self.propertyInfosByPropertyKeys allValues];
        if ([cls conformsToProtocol:@protocol(OOUniqueModel)])
        {
            self.uniquePropertyKey = [self.cls oo_uniquePropertyKey];
            self.mapTable = [[OOMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
            OOPropertyInfo *uniquePropertyInfo = self.propertyInfosByPropertyKeys[self.uniquePropertyKey];
            if (uniquePropertyInfo && uniquePropertyInfo.encodingType != OOEncodingTypeUnknow && uniquePropertyInfo.encodingType != OOEncodingTypeOtherObject)
            {
                NSCAssert(uniquePropertyInfo && uniquePropertyInfo.encodingType != OOEncodingTypeUnknow && uniquePropertyInfo.encodingType != OOEncodingTypeOtherObject, @"unique key can not support this encoding type");
            }
        }
        if ([cls conformsToProtocol:@protocol(OOJsonModel)])
        {
            NSMutableArray *jsonPropertyInfos = [NSMutableArray array];
            NSDictionary *jsonKeyPathsByPropertyKeys = [cls oo_jsonKeyPathsByPropertyKeys];
            [jsonKeyPathsByPropertyKeys enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull propertyKey, NSString *_Nonnull jsonKeyPath, BOOL *_Nonnull stop) {
                OOPropertyInfo *propertyInfo = self.propertyInfosByPropertyKeys[propertyKey];
                NSCAssert(propertyInfo.ivarKey.length, @"[class:%@,propertyKey:%@] [property do not have ivar]", NSStringFromClass(cls), propertyKey);
                NSCAssert(jsonKeyPath.length, @"[class:%@,propertyKey:%@] [json key path is null]", NSStringFromClass(cls), propertyKey);
                NSArray *jsonKeyPathArr = [jsonKeyPath componentsSeparatedByString:@"."];
                propertyInfo.jsonKeyPathInString = jsonKeyPath;
                propertyInfo.jsonKeyPathInArray = jsonKeyPathArr;
                if ((propertyInfo.encodingType == OOEncodingTypeOtherObject && ![propertyInfo.propertyCls conformsToProtocol:@protocol(OOJsonModel)]) || propertyInfo.encodingType == OOEncodingTypeUnknow)
                {
                    NSCAssert([cls respondsToSelector:@selector(oo_jsonValueTransformerForPropertyKey:)], @"[class:%@,propertyKey:%@] [class should implement + (NSValueTransformer)oo_jsonValueTransformerForPropertyKey:]", NSStringFromClass(cls), propertyInfo.propertyKey);
                    propertyInfo.jsonValueTransformer = [self.cls oo_jsonValueTransformerForPropertyKey:propertyInfo.propertyKey];
                }
                [jsonPropertyInfos addObject:propertyInfo];
            }];
            self.jsonPropertyInfos = jsonPropertyInfos.count ? jsonPropertyInfos : nil;
        }
        if ([cls conformsToProtocol:@protocol(OODbModel)])
        {
            NSMutableArray *dbPropertyInfos = [NSMutableArray array];
            NSArray *dbPropertyKeys = [cls oo_dbColumnNamesInPropertyKeys];
            [dbPropertyKeys enumerateObjectsUsingBlock:^(NSString *_Nonnull propertyKey, NSUInteger idx, BOOL *_Nonnull stop) {
                OOPropertyInfo *propertyInfo = self.propertyInfosByPropertyKeys[propertyKey];
                NSCAssert(propertyInfo.ivarKey.length, @"[class:%@,propertyKey:%@] [property do not have ivar]", NSStringFromClass(cls), propertyKey);
                if (propertyInfo.encodingType >= OOEncodingTypeBool && propertyInfo.encodingType <= OOEncodingTypeUInt64)
                {
                    propertyInfo.dbColumnType = OODbColumnTypeInteger;
                }
                else if (propertyInfo.encodingType == OOEncodingTypeFloat || propertyInfo.encodingType == OOEncodingTypeDouble || propertyInfo.encodingType == OOEncodingTypeNSDate)
                {
                    propertyInfo.dbColumnType = OODbColumnTypeReal;
                }
                else if (propertyInfo.encodingType & OOEncodingTypeNSData)
                {
                    propertyInfo.dbColumnType = OODbColumnTypeBlob;
                }
                else if (propertyInfo.encodingType == OOEncodingTypeNSString || propertyInfo.encodingType == OOEncodingTypeNSURL || propertyInfo.encodingType == OOEncodingTypeNSNumber)
                {
                    propertyInfo.dbColumnType = OODbColumnTypeText;
                }
                else
                {
                    if ((propertyInfo.encodingType == OOEncodingTypeOtherObject && ![propertyInfo.propertyCls conformsToProtocol:@protocol(OODbModel)]) || propertyInfo.encodingType == OOEncodingTypeUnknow)
                    {
                        NSCAssert([cls respondsToSelector:@selector(oo_dbValueTransformerForPropertyKey:)], @"[class:%@,propertyKey:%@] [class should implement + (NSValueTransformer)oo_dbValueTransformerForPropertyKey:]", NSStringFromClass(cls), propertyInfo.propertyKey);
                        propertyInfo.dbValueTransformer = [self.cls oo_dbValueTransformerForPropertyKey:propertyInfo.propertyKey];
                    }
                    NSCAssert([cls respondsToSelector:@selector(oo_dbColumnTypeForPropertyKey:)], @"[class:%@,propertyKey:%@] [class should implement + (OODbColumnType)oo_dbColumnTypeForPropertyKey:]", NSStringFromClass(cls), propertyInfo.propertyKey);
                    propertyInfo.dbColumnType = [self.cls oo_dbColumnTypeForPropertyKey:propertyInfo.propertyKey];
                }
                [dbPropertyInfos addObject:propertyInfo];
            }];
            self.dbPropertyInfos = dbPropertyInfos.count ? dbPropertyInfos : nil;
            self.dbTableName = NSStringFromClass(cls);
            if (self.uniquePropertyKey)
            {
                self.uniqueSelectSql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=?", self.dbTableName, [self.propertyInfosByPropertyKeys[self.uniquePropertyKey] propertyKey]];
            }
            if (self.dbPropertyInfos)
            {
                NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", self.dbTableName];
                NSMutableString *sql1 = [NSMutableString stringWithFormat:@"INSERT INTO %@ (", self.dbTableName];
                NSMutableString *sql2 = [NSMutableString stringWithFormat:@" VALUES ("];
                [self.dbPropertyInfos enumerateObjectsUsingBlock:^(OOPropertyInfo *_Nonnull propertyInfo, NSUInteger idx, BOOL *_Nonnull stop) {
                    [sql appendFormat:@"%@=?,", propertyInfo.propertyKey];
                    [sql1 appendFormat:@"%@,", propertyInfo.propertyKey];
                    [sql2 appendFormat:@"?,"];
                }];
                [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
                [sql appendFormat:@" WHERE %@=?;", [self.propertyInfosByPropertyKeys[self.uniquePropertyKey] propertyKey]];
                self.updateSql = sql;
                [sql1 deleteCharactersInRange:NSMakeRange(sql1.length - 1, 1)];
                [sql1 appendFormat:@")"];
                [sql2 deleteCharactersInRange:NSMakeRange(sql2.length - 1, 1)];
                [sql2 appendFormat:@")"];
                self.insertSql = [NSString stringWithFormat:@"%@%@", sql1, sql2];
            }
        }
    }
    return self;
}

- (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property))block
{
    Class cls = self.cls;
    while (YES)
    {
        if (cls == NSObject.class)
        {
            break;
        }
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);
        if (properties == NULL)
        {
            cls = cls.superclass;
            continue;
        }
        for (unsigned i = 0; i < count; i++)
        {
            objc_property_t property = properties[i];
            block(property);
        }
        free(properties);
        cls = cls.superclass;
    }
}

@end

@implementation OOPropertyInfo

- (instancetype)initWithProperty:(objc_property_t)property
{
    self = [super init];
    if (self)
    {
        self.propertyKey = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSString *attributes = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        for (NSString *attr in [attributes componentsSeparatedByString:@","])
        {
            const char *attribute = [attr UTF8String];
            switch (attribute[0])
            {
                case 'T':
                {
                    const char *encoding = attribute + 1;
                    if (encoding[0] == '@')
                    {
                        if (strcmp(encoding, "@\"NSString\"") == 0)
                        {
                            self.encodingType = OOEncodingTypeNSString;
                        }
                        else if (strcmp(encoding, "@\"NSNumber\"") == 0)
                        {
                            self.encodingType = OOEncodingTypeNSNumber;
                        }
                        else if (strcmp(encoding, "@\"NSURL\"") == 0)
                        {
                            self.encodingType = OOEncodingTypeNSURL;
                        }
                        else if (strcmp(encoding, "@\"NSDate\"") == 0)
                        {
                            self.encodingType = OOEncodingTypeNSDate;
                        }
                        else if (strcmp(encoding, "@\"NSData\"") == 0)
                        {
                            self.encodingType = OOEncodingTypeNSData;
                        }
                        else
                        {
                            self.encodingType = OOEncodingTypeOtherObject;
                        }
                        size_t size = strlen(encoding);
                        if (size > 3)
                        {
                            NSString *clsName = [[NSString alloc] initWithBytes:encoding + 2 length:size - 3 encoding:NSUTF8StringEncoding];
                            self.propertyCls = NSClassFromString(clsName);
                        }
                    }
                    else
                    {
                        if (strcmp(encoding, @encode(char)) == 0)
                        {
                            self.encodingType = OOEncodingTypeInt8;
                        }
                        else if (strcmp(encoding, @encode(unsigned char)) == 0)
                        {
                            self.encodingType = OOEncodingTypeUInt8;
                        }
                        else if (strcmp(encoding, @encode(short)) == 0)
                        {
                            self.encodingType = OOEncodingTypeInt16;
                        }
                        else if (strcmp(encoding, @encode(unsigned short)) == 0)
                        {
                            self.encodingType = OOEncodingTypeUInt16;
                        }
                        else if (strcmp(encoding, @encode(int)) == 0)
                        {
                            self.encodingType = OOEncodingTypeInt32;
                        }
                        else if (strcmp(encoding, @encode(unsigned int)) == 0)
                        {
                            self.encodingType = OOEncodingTypeUInt32;
                        }
                        else if (strcmp(encoding, @encode(long)) == 0)
                        {
                            self.encodingType = OOEncodingTypeInt64;
                        }
                        else if (strcmp(encoding, @encode(unsigned long)) == 0)
                        {
                            self.encodingType = OOEncodingTypeUInt64;
                        }
                        else if (strcmp(encoding, @encode(long long)) == 0)
                        {
                            self.encodingType = OOEncodingTypeInt64;
                        }
                        else if (strcmp(encoding, @encode(unsigned long long)) == 0)
                        {
                            self.encodingType = OOEncodingTypeUInt64;
                        }
                        else if (strcmp(encoding, @encode(float)) == 0)
                        {
                            self.encodingType = OOEncodingTypeFloat;
                        }
                        else if (strcmp(encoding, @encode(double)) == 0)
                        {
                            self.encodingType = OOEncodingTypeDouble;
                        }
                        else if (strcmp(encoding, @encode(bool)) == 0)
                        {
                            self.encodingType = OOEncodingTypeBool;
                        }
                        else
                        {
                            self.encodingType = OOEncodingTypeUnknow;
                        }
                    }
                }
                break;
                case 'V':
                {
                    const char *ivar_key = attribute + 1;
                    if (strlen(ivar_key) > 0)
                    {
                        self.ivarKey = [NSString stringWithCString:ivar_key encoding:NSUTF8StringEncoding];
                    }
                }
                break;
                case 'G':
                {
                    NSString *getterString = [NSString stringWithCString:attribute + 1 encoding:NSUTF8StringEncoding];
                    self.getter = NSSelectorFromString(getterString);
                }
                break;
                case 'S':
                {
                    NSString *setterString = [NSString stringWithCString:attribute + 1 encoding:NSUTF8StringEncoding];
                    self.setter = NSSelectorFromString(setterString);
                }
                case 'C':
                {
                    self.referenceType = OOReferenceTypeCopy;
                }
                break;
                case '&':
                {
                    self.referenceType = OOReferenceTypeStrongRetain;
                }
                break;
                case 'W':
                {
                    self.referenceType = OOReferenceTypeWeak;
                }
                break;
                case 'R':
                {
                    self.propertyType |= OOPropertyTypeReadonly;
                }
                break;
                case 'N':
                {
                    self.propertyType |= OOPropertyTypeNonatomic;
                }
                break;
                case 'D':
                {
                    self.propertyType |= OOPropertyTypeDynamic;
                }
                break;
                default:
                    break;
            }
        }
        if (self.ivarKey && !(self.propertyType & OOPropertyTypeDynamic))
        {
            if (!self.getter)
            {
                NSString *getterString = self.propertyKey;
                self.getter = NSSelectorFromString(getterString);
            }
            if (!self.setter && !(self.propertyType & OOPropertyTypeReadonly))
            {
                NSString *setterString = self.propertyKey;
                setterString = [NSString stringWithFormat:@"set%@:", [NSString stringWithFormat:@"%@%@", [[setterString substringToIndex:1] capitalizedString], [setterString substringFromIndex:1]]];
                self.setter = NSSelectorFromString(setterString);
            }
        }
        self.ownClassInfo = nil;
        self.jsonKeyPathInString = nil;
        self.jsonKeyPathInArray = nil;
        self.jsonKeyPathInArray = nil;
        self.jsonValueTransformer = nil;
        self.dbColumnType = OODbColumnTypeUnknow;
        self.dbValueTransformer = nil;
    }
    return self;
}

@end
