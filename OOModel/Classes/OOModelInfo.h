//
//  OOPropertyInfo.h
//  OOModel
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "OODatabase.h"
#import "OOMapTable.h"
typedef NS_ENUM(NSInteger,OODbColumnType) {
    OODbColumnTypeText,
    OODbColumnTypeInteger,
    OODbColumnTypeReal,
    OODbColumnTypeBlob
};

typedef NS_ENUM(NSInteger,OOEncodingType) {
    
    OOEncodingTypeUnSupported=0,
    
    OOEncodingTypeBool=1<<1,
    OOEncodingTypeInt8=1<<2,
    OOEncodingTypeUInt8=1<<3,
    OOEncodingTypeInt16=1<<4,
    OOEncodingTypeUInt16=1<<5,
    OOEncodingTypeInt32=1<<6,
    OOEncodingTypeUInt32=1<<7,
    OOEncodingTypeInt64=1<<8,
    OOEncodingTypeUInt64=1<<9,
    OOEncodingTypeFloat=1<<10,
    OOEncodingTypeDouble=1<<11,
    
    OOEncodingTypeCType=OOEncodingTypeBool|OOEncodingTypeInt8|OOEncodingTypeUInt8|OOEncodingTypeInt16|OOEncodingTypeUInt16|OOEncodingTypeInt32|OOEncodingTypeUInt32|OOEncodingTypeInt64|OOEncodingTypeUInt64|OOEncodingTypeFloat|OOEncodingTypeDouble,
    
    OOEncodingTypeNSString=1<<12,
    OOEncodingTypeNSNumber=1<<13,
    OOEncodingTypeNSURL=1<<14,
    OOEncodingTypeNSDate=1<<15,
    OOEncodingTypeNSData=1<<16,
    OOEncodingTypeUnsupportedObject=1<<17,
    OOEncodingTypeObject=OOEncodingTypeNSString|OOEncodingTypeNSNumber|OOEncodingTypeNSURL|OOEncodingTypeNSDate|OOEncodingTypeNSData|OOEncodingTypeUnsupportedObject,
};

typedef NS_ENUM(NSInteger,OOReferenceType) {
    
    OOReferenceTypeAssign,
    OOReferenceTypeWeak,
    OOReferenceTypeStrongRetain,
    OOReferenceTypeCopy
    
};

typedef NS_ENUM(NSInteger,OOPropertyType) {
    OOPropertyTypeUnknow=0,
    OOPropertyTypeNonatomic=1<<0,
    OOPropertyTypeDynamic=1<<1,
    OOPropertyTypeReadonly=1<<2
};

@class OOClassInfo;

@interface OOPropertyInfo : NSObject

@property (nonatomic,copy  ,readonly) NSString           *ivarKey;
@property (nonatomic,copy  ,readonly) NSString           *propertyKey;
@property (nonatomic,assign,readonly) Class              propertyCls;
@property (nonatomic,assign,readonly) Class              ownCls;
@property (nonatomic,assign,readonly) OOClassInfo        *propertyClassInfo;
@property (nonatomic,assign,readonly) OOClassInfo        *ownClassInfo;
@property (nonatomic,assign,readonly) SEL                setter;
@property (nonatomic,assign,readonly) SEL                getter;
@property (nonatomic,assign,readonly) OOEncodingType     encodingType;
@property (nonatomic,assign,readonly) OOPropertyType     propertyType;
@property (nonatomic,assign,readonly) ptrdiff_t          ivarOffset;
@property (nonatomic,assign,readonly) OOReferenceType    referenceType;
@property (nonatomic,copy  ,readonly) id                 jsonKeyPath;
@property (nonatomic,strong,readonly) NSValueTransformer *jsonValueTransformer;
@property (nonatomic,strong,readonly) NSString           *dbColumn;
@property (nonatomic,strong,readonly) NSValueTransformer *dbValueTransformer;
@property (nonatomic,assign,readonly) OODbColumnType     dbColumnType;
@property (nonatomic,assign,readonly) SEL                jsonForwards;
@property (nonatomic,assign,readonly) SEL                jsonBackwards;

+ (OOPropertyInfo*)propertyInfoWithProperty:(objc_property_t)property ownCls:(Class)ownCls;

@end

@interface OOClassInfo : NSObject

@property (nonatomic,assign,readonly) Class          cls;

@property (nonatomic,strong,readonly) NSArray        *propertyKeys;
@property (nonatomic,strong,readonly) NSArray        *propertyInfos;
@property (nonatomic,strong,readonly) NSArray        *jsonPropertyInfos;
@property (nonatomic,strong,readonly) NSDictionary   *propertyInfosByPropertyKeys;

@property (nonatomic,assign,readonly) BOOL           conformsToOOJsonModel;
@property (nonatomic,assign,readonly) BOOL           hasJsonValueTransformer;

@property (nonatomic,assign,readonly) BOOL           conformsToOOUniqueModel;
@property (nonatomic,copy  ,readonly) NSString       *uniquePropertyKey;
@property (nonatomic                ) OOMapTable     *mapTable;

@property (nonatomic,assign,readonly) BOOL           conformsToOODbModel;
@property (nonatomic,strong,readonly) NSArray        *dbPropertyInfos;
@property (nonatomic,assign,readonly) BOOL           hasDbValueTransformer;
@property (nonatomic,assign,readonly) BOOL           hasDbColumnType;
@property (nonatomic                ) OODatabase     *database;
@property (nonatomic,copy  ,readonly) NSString       *dbTable;
@property (nonatomic,assign         ) NSTimeInterval dbTimestamp;
+ (instancetype)classInfoWithClass:(Class)cls;
+ (void)setGlobalDatabase:(OODatabase*)database;
+ (NSRecursiveLock*)globalLock;
@end

