//
//  OOPropertyInfo.h
//  OOModel
//

#import "OODb.h"
#import "OOMapTable.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, OODbColumnType) {
    OODbColumnTypeUnknow,
    OODbColumnTypeText,
    OODbColumnTypeInteger,
    OODbColumnTypeReal,
    OODbColumnTypeBlob
};

typedef NS_ENUM(NSInteger, OOEncodingType) {
    OOEncodingTypeUnknow = 0,

    OOEncodingTypeBool = 1 << 1,
    OOEncodingTypeInt8 = 1 << 2,
    OOEncodingTypeUInt8 = 1 << 3,
    OOEncodingTypeInt16 = 1 << 4,
    OOEncodingTypeUInt16 = 1 << 5,
    OOEncodingTypeInt32 = 1 << 6,
    OOEncodingTypeUInt32 = 1 << 7,
    OOEncodingTypeInt64 = 1 << 8,
    OOEncodingTypeUInt64 = 1 << 9,
    OOEncodingTypeFloat = 1 << 10,
    OOEncodingTypeDouble = 1 << 11,

    OOEncodingTypeCType = OOEncodingTypeBool | OOEncodingTypeInt8 | OOEncodingTypeUInt8 | OOEncodingTypeInt16 | OOEncodingTypeUInt16 | OOEncodingTypeInt32 | OOEncodingTypeUInt32 | OOEncodingTypeInt64 | OOEncodingTypeUInt64 | OOEncodingTypeFloat | OOEncodingTypeDouble,

    OOEncodingTypeNSString = 1 << 12,
    OOEncodingTypeNSNumber = 1 << 13,
    OOEncodingTypeNSURL = 1 << 14,
    OOEncodingTypeNSDate = 1 << 15,
    OOEncodingTypeNSData = 1 << 16,
    OOEncodingTypeOtherObject = 1 << 17,
    OOEncodingTypeObject = OOEncodingTypeNSString | OOEncodingTypeNSNumber | OOEncodingTypeNSURL | OOEncodingTypeNSDate | OOEncodingTypeNSData | OOEncodingTypeOtherObject,
};

typedef NS_ENUM(NSInteger, OOReferenceType) {
    OOReferenceTypeAssign,
    OOReferenceTypeWeak,
    OOReferenceTypeStrongRetain,
    OOReferenceTypeCopy
};

typedef NS_ENUM(NSInteger, OOPropertyType) {
    OOPropertyTypeUnknow = 0,
    OOPropertyTypeNonatomic = 1 << 0,
    OOPropertyTypeDynamic = 1 << 1,
    OOPropertyTypeReadonly = 1 << 2
};

@interface OOClassInfo : NSObject

@property(nonatomic, assign, readonly) Class cls;

@property(nonatomic, strong, readonly) NSArray *propertyKeys;
@property(nonatomic, strong, readonly) NSArray *propertyInfos;
@property(nonatomic, strong, readonly) NSDictionary *propertyInfosByPropertyKeys;

@property(nonatomic, strong, readonly) NSArray *jsonPropertyInfos;

@property(nonatomic) OOMapTable *mapTable;
@property(nonatomic, copy, readonly) NSString *uniquePropertyKey;

@property(nonatomic, strong, readonly) NSArray *dbPropertyInfos;
@property(nonatomic) OODb *database;
@property(nonatomic, copy, readonly) NSString *dbTableName;
@property(nonatomic, copy, readonly) NSString *uniqueSelectSql;
@property(nonatomic, copy, readonly) NSString *insertSql;
@property(nonatomic, copy, readonly) NSString *updateSql;

- (instancetype)initWithClass:(Class)cls;

@end

@interface OOPropertyInfo : NSObject

@property(nonatomic, copy, readonly) NSString *propertyKey;
@property(nonatomic, assign, readonly) Class propertyCls;
@property(nonatomic, assign, readonly) OOEncodingType encodingType;
@property(nonatomic, assign, readonly) OOPropertyType propertyType;
@property(nonatomic, assign, readonly) OOReferenceType referenceType;
@property(nonatomic, assign, readonly) SEL setter;
@property(nonatomic, assign, readonly) SEL getter;

@property(nonatomic, weak, readonly) OOClassInfo *ownClassInfo;

@property(nonatomic, strong, readonly) NSValueTransformer *jsonValueTransformer;
@property(nonatomic, copy, readonly) NSString *jsonKeyPathInString;
@property(nonatomic, strong, readonly) NSArray *jsonKeyPathInArray;
@property(nonatomic, strong, readonly) NSValueTransformer *dbValueTransformer;
@property(nonatomic, assign, readonly) OODbColumnType dbColumnType;

- (instancetype)initWithProperty:(objc_property_t)property;

@end
