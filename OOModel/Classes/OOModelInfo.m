//
//  OOPropertyInfo.m
//  OOModel
//

#import "OOModelInfo.h"
#import "NSObject+OOModel.h"
@interface OOPropertyInfo()

@property (nonatomic, copy  ) NSString           *ivarKey;
@property (nonatomic, copy  ) NSString           *propertyKey;
@property (nonatomic, assign) Class              propertyCls;
@property (nonatomic, assign) Class              ownCls;
@property (nonatomic, assign) OOClassInfo        *propertyClassInfo;
@property (nonatomic, assign) OOClassInfo        *ownClassInfo;
@property (nonatomic, assign) SEL                setter;
@property (nonatomic, assign) SEL                getter;
@property (nonatomic, assign) OOEncodingType     encodingType;
@property (nonatomic, assign) OOPropertyType     propertyType;
@property (nonatomic, assign) ptrdiff_t          ivarOffset;
@property (nonatomic, assign) OOReferenceType    referenceType;
@property (nonatomic, copy  ) id                 jsonKeyPath;
@property (nonatomic, strong) NSValueTransformer *jsonValueTransformer;
@property (nonatomic, strong) NSString           *dbColumn;
@property (nonatomic, strong) NSValueTransformer *dbValueTransformer;
@property (nonatomic, assign) OODbColumnType     dbColumnType;
@property (nonatomic, assign) SEL                jsonForwards;
@property (nonatomic, assign) SEL                jsonBackwards;

@end

@interface OOClassInfo ()

@property (nonatomic, assign) Class        cls;
@property (nonatomic, strong) NSArray      *propertyInfos;
@property (nonatomic, strong) NSArray      *dbPropertyInfos;
@property (nonatomic, strong) NSArray      *jsonPropertyInfos;
@property (nonatomic, strong) NSArray      *propertyKeys;
@property (nonatomic, strong) NSDictionary *uninitializedPropertyInfosByPropertyKeys;
@property (nonatomic, strong) NSDictionary *propertyInfosByPropertyKeys;
@property (nonatomic, assign) BOOL         conformsToOOJsonModel;
@property (nonatomic, assign) BOOL         conformsToOODbModel;
@property (nonatomic, assign) BOOL         conformsToOOUniqueModel;
@property (nonatomic, assign) BOOL         hasJsonValueTransformer;
@property (nonatomic, assign) BOOL         hasDbValueTransformer;
@property (nonatomic, assign) BOOL         hasDbColumnType;
@property (nonatomic, strong) NSMapTable   *mapTable;
@property (nonatomic, strong) dispatch_semaphore_t mapTableSemaphore;
@property (nonatomic, copy) NSString     *uniquePropertyKey;
@property (nonatomic, copy) NSString     *dbTable;

@end

@implementation OOPropertyInfo

+ (instancetype)propertyInfoWithProperty:(objc_property_t)property ownCls:(__unsafe_unretained Class)ownCls{
    return [[self alloc]initWithProperty:property ownCls:ownCls];
}

- (instancetype)initWithProperty:(objc_property_t)property ownCls:(__unsafe_unretained Class)ownCls{
    self=[super init];
    if (self) {
        self.ownCls=ownCls;
        self.propertyKey=[NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSString * attributes=[NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        for (NSString * attr in [attributes componentsSeparatedByString:@","]){
            const char * attribute=[attr UTF8String];
            switch (attribute[0]) {
                case 'T': {
                    const char * encoding=attribute+1;
                    if (encoding[0]=='@') {
                        if (strcmp(encoding, "@\"NSString\"")==0) {
                            self.encodingType=OOEncodingTypeNSString;
                        }else if (strcmp(encoding, "@\"NSNumber\"")==0){
                            self.encodingType=OOEncodingTypeNSNumber;
                        }else if (strcmp(encoding, "@\"NSURL\"")==0){
                            self.encodingType=OOEncodingTypeNSURL;
                        }else if (strcmp(encoding, "@\"NSDate\"")==0){
                            self.encodingType=OOEncodingTypeNSDate;
                        }else if (strcmp(encoding, "@\"NSData\"")==0){
                            self.encodingType=OOEncodingTypeNSData;
                        }else{
                            self.encodingType=OOEncodingTypeUnsupportedObject;
                        }
                        size_t size=strlen(encoding);
                        if (size>3) {
                            NSString *clsName=[[NSString alloc]initWithBytes:encoding+2 length:size-3 encoding:NSUTF8StringEncoding];
                            self.propertyCls=NSClassFromString(clsName);
                        }
                    }else{
                        if (strcmp(encoding, @encode(char)) == 0) {
                            self.encodingType=OOEncodingTypeInt8;
                        }else if (strcmp(encoding, @encode(unsigned char)) == 0) {
                            self.encodingType=OOEncodingTypeUInt8;
                        }else if (strcmp(encoding, @encode(short)) == 0) {
                            self.encodingType=OOEncodingTypeInt16;
                        }else if (strcmp(encoding, @encode(unsigned short)) == 0) {
                            self.encodingType=OOEncodingTypeUInt16;
                        }else if (strcmp(encoding, @encode(int)) == 0) {
                            self.encodingType=OOEncodingTypeInt32;
                        }else if (strcmp(encoding, @encode(unsigned int)) == 0) {
                            self.encodingType=OOEncodingTypeUInt32;
                        }else if (strcmp(encoding, @encode(long)) == 0) {
                            self.encodingType=OOEncodingTypeInt64;
                        }else if (strcmp(encoding, @encode(unsigned long)) == 0) {
                            self.encodingType=OOEncodingTypeUInt64;
                        }else if (strcmp(encoding, @encode(long long)) == 0) {
                            self.encodingType=OOEncodingTypeInt64;
                        }else if (strcmp(encoding, @encode(unsigned long long)) == 0) {
                            self.encodingType=OOEncodingTypeUInt64;
                        }else if (strcmp(encoding, @encode(float)) == 0) {
                            self.encodingType=OOEncodingTypeFloat;
                        }else if (strcmp(encoding, @encode(double)) == 0) {
                            self.encodingType=OOEncodingTypeDouble;
                        }else if (strcmp(encoding, @encode(bool)) == 0) {
                            self.encodingType=OOEncodingTypeBool;
                        }else {
                            self.encodingType=OOEncodingTypeUnSupported;
                        }
                    }
                }
                    break;
                case 'V': {
                    const char * ivar_key=attribute+1;
                    if (strlen(ivar_key)>0) {
                        self.ivarKey=[NSString stringWithCString:ivar_key encoding:NSUTF8StringEncoding];
                    }
                }
                    break;
                case 'G': {
                    NSString * getterString = [NSString stringWithCString:attribute+1 encoding:NSUTF8StringEncoding];
                    self.getter=NSSelectorFromString(getterString);
                }
                    break;
                case 'S': {
                    NSString * setterString = [NSString stringWithCString:attribute+1 encoding:NSUTF8StringEncoding];
                    self.setter=NSSelectorFromString(setterString);
                }
                case 'C': {
                    self.referenceType=OOReferenceTypeCopy;
                }
                    break;
                case '&': {
                    self.referenceType=OOReferenceTypeStrongRetain;
                }
                    break;
                case 'W': {
                    self.referenceType=OOReferenceTypeWeak;
                }
                    break;
                case 'R': {
                    self.propertyType|=OOPropertyTypeReadonly;
                }
                    break;
                case 'N': {
                    self.propertyType|=OOPropertyTypeNonatomic;
                }
                    break;
                case 'D': {
                    self.propertyType|=OOPropertyTypeDynamic;
                }
                    break;
                default:
                    break;
            }
        }
        Ivar ivar= class_getInstanceVariable(ownCls, [self.ivarKey UTF8String]);
        self.ivarOffset=ivar_getOffset(ivar);
        if (self.ivarKey&&!(self.propertyType&OOPropertyTypeDynamic)) {
            if (!self.getter) {
                NSString * getterString = self.propertyKey;
                self.getter=NSSelectorFromString(getterString);
            }
            if (!self.setter&&!(self.propertyType&OOPropertyTypeReadonly)) {
                NSString * setterString =self.propertyKey;
                setterString=[NSString stringWithFormat:@"set%@:",[NSString stringWithFormat:@"%@%@",[[setterString substringToIndex:1] capitalizedString],[setterString substringFromIndex:1]]];
                self.setter=NSSelectorFromString(setterString);
            }
        }
    }
    return self;
}
@end



@implementation OOClassInfo
+ (instancetype)classInfoWithClass:(Class)cls{
    OOClassInfo *classInfo=[[self alloc]initWithClass:cls];
    
    return classInfo;
}
- (instancetype)initWithClass:(Class)cls{
    self=[super init];
    if (self) {
        self.cls=cls;
        if ([cls conformsToProtocol:@protocol(OOJsonModel)]) {
            self.conformsToOOJsonModel=YES;
            if ([cls respondsToSelector:@selector(jsonValueTransformerForPropertyKey:)]) {
                self.hasJsonValueTransformer=YES;
            }
        }
        if ([cls conformsToProtocol:@protocol(OODbModel)]) {
            self.conformsToOODbModel=YES;
            if ([cls respondsToSelector:@selector(dbValueTransformerForPropertyKey:)]) {
                self.hasDbValueTransformer=YES;
            }
            if ([cls respondsToSelector:@selector(dbColumnTypeForPropertyKey:)]) {
                self.hasDbColumnType=YES;
            }
        }
        if ([cls conformsToProtocol:@protocol(OOUniqueModel)]) {
            self.conformsToOOUniqueModel=YES;
        }
    }
    return self;
}



- (OOPropertyInfo*)initializePropertyInfo:(OOPropertyInfo*)propertyInfo{
    if (!propertyInfo.ivarKey||(propertyInfo.propertyType&OOPropertyTypeReadonly)) {
        return nil;
    }
    Class cls=self.cls;
    if (self.conformsToOOJsonModel) {
        NSString *jsonKeyPath=[cls jsonKeyPathsByPropertyKeys][propertyInfo.propertyKey];
        if (jsonKeyPath.length!=0) {
            NSArray *jsonKeyPathArr=[jsonKeyPath componentsSeparatedByString:@"."];
            if (jsonKeyPathArr.count>1) {
                propertyInfo.jsonKeyPath=jsonKeyPathArr;
            }else{
                propertyInfo.jsonKeyPath=jsonKeyPath;
            }
        }
        if (self.hasJsonValueTransformer) {
            propertyInfo.jsonValueTransformer=[self.cls jsonValueTransformerForPropertyKey:propertyInfo.propertyKey];
        }
        if(propertyInfo.encodingType&OOEncodingTypeUnsupportedObject){
            if ([propertyInfo.propertyCls conformsToProtocol:@protocol(OOJsonModel)]) {
                propertyInfo.jsonForwards=@selector(oo_modelWithJson:);
                propertyInfo.jsonBackwards=@selector(oo_jsonDictionary);
            }
        }
    }
    if (self.conformsToOODbModel) {
        propertyInfo.dbColumn=OOCOMPACT(propertyInfo.propertyKey);
        if (self.hasDbValueTransformer) {
            propertyInfo.dbValueTransformer=[self.cls dbValueTransformerForPropertyKey:propertyInfo.propertyKey];
        }
        if (propertyInfo.encodingType>=OOEncodingTypeBool&&propertyInfo.encodingType<=OOEncodingTypeUInt64) {
            propertyInfo.dbColumnType=OODbColumnTypeInteger;
        }else if (propertyInfo.encodingType==OOEncodingTypeFloat||propertyInfo.encodingType==OOEncodingTypeDouble||propertyInfo.encodingType==OOEncodingTypeNSDate||propertyInfo.encodingType==OOEncodingTypeNSNumber) {
            propertyInfo.dbColumnType=OODbColumnTypeReal;
        }else if (propertyInfo.encodingType&OOEncodingTypeNSData){
            propertyInfo.dbColumnType=OODbColumnTypeBlob;
        }else if (propertyInfo.encodingType&OOEncodingTypeUnsupportedObject){
            if (self.hasDbColumnType) {
                propertyInfo.dbColumnType=[self.cls dbColumnTypeForPropertyKey:propertyInfo.propertyKey];
            }
        }else{
            propertyInfo.dbColumnType=OODbColumnTypeText;
        }
    }
    propertyInfo.ownClassInfo=self;
    return propertyInfo;
}

- (NSString*)uniquePropertyKey{
    if (!_uniquePropertyKey) {
        _uniquePropertyKey=[self.cls uniquePropertyKey];
    }
    return  _uniquePropertyKey;
}

- (NSString*)dbTable{
    if (!_dbTable) {
        _dbTable=OOCOMPACT(NSStringFromClass(self.cls));
    }
    return _dbTable;
}
- (NSDictionary*)propertyInfosByPropertyKeys{
    if(!_propertyInfosByPropertyKeys){
        NSMutableDictionary * propertyInfosByPropertyKeys=[NSMutableDictionary dictionary];
        [self.uninitializedPropertyInfosByPropertyKeys enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, OOPropertyInfo *  _Nonnull propertyInfo, BOOL * _Nonnull stop) {
            propertyInfo =[self initializePropertyInfo:propertyInfo];
            if (propertyInfo) {
                [propertyInfosByPropertyKeys setObject:propertyInfo forKey:key];
            }
        }];
        _propertyInfosByPropertyKeys=propertyInfosByPropertyKeys;
    }
    return _propertyInfosByPropertyKeys;
}
- (NSArray*)dbPropertyInfos{
    if (!_dbPropertyInfos) {
        NSMutableArray *dbPropertyInfos=[NSMutableArray array];
        for (OOPropertyInfo * propertyInfo in self.propertyInfos){
            BOOL shouldAdd=NO;
            for (NSString * propertyKey in [self.cls dbColumnsInPropertyKeys]){
                if ([propertyKey isEqualToString:propertyInfo.propertyKey]) {
                    shouldAdd=YES;
                    break;
                }
            }
            if (shouldAdd) {
                [dbPropertyInfos addObject:propertyInfo];
            }
        }
        _dbPropertyInfos=dbPropertyInfos;
    }
    return _dbPropertyInfos;
}

- (NSArray*)jsonPropertyInfos{
    if (!_jsonPropertyInfos) {
        NSMutableArray *jsonPropertyInfos=[NSMutableArray array];
        for (OOPropertyInfo * propertyInfo in self.propertyInfos){
            BOOL shouldAdd=NO;
            for (NSString * propertyKey in [[self.cls jsonKeyPathsByPropertyKeys]allKeys]){
                if ([propertyKey isEqualToString:propertyInfo.propertyKey]) {
                    shouldAdd=YES;
                    break;
                }
            }
            if (shouldAdd) {
                [jsonPropertyInfos addObject:propertyInfo];
            }
        }
        _jsonPropertyInfos=jsonPropertyInfos;
    }
    return _jsonPropertyInfos;
}

- (NSArray*)propertyInfos{
    if (!_propertyInfos) {
        _propertyInfos=[self.propertyInfosByPropertyKeys allValues];
    }
    return _propertyInfos;
}

- (NSArray*)propertyKeys{
    if (!_propertyKeys) {
        _propertyKeys=[self.uninitializedPropertyInfosByPropertyKeys allKeys];
    }
    return _propertyKeys;
}

- (NSDictionary*)uninitializedPropertyInfosByPropertyKeys{
    if (!_uninitializedPropertyInfosByPropertyKeys) {
        NSMutableDictionary *propertyInfosByPropertyKeys=[NSMutableDictionary dictionary];
        [self enumeratePropertiesUsingBlock:^(objc_property_t property) {
            OOPropertyInfo *propertyInfo=[OOPropertyInfo propertyInfoWithProperty:property ownCls:self.cls];
            if (propertyInfo.ivarKey) {
                [propertyInfosByPropertyKeys setObject:propertyInfo forKey:propertyInfo.propertyKey];
            }
        }];
        _uninitializedPropertyInfosByPropertyKeys=propertyInfosByPropertyKeys;
    }
    return _uninitializedPropertyInfosByPropertyKeys;
}

- (NSMapTable*)mapTable{
    if (!_mapTable) {
        _mapTable=[NSMapTable strongToWeakObjectsMapTable];
    }
    return _mapTable;
}
- (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property))block{
    Class cls=self.cls;
    while (YES) {
        if (cls==NSObject.class) {
            break;
        }
        unsigned int count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);
        if (properties == NULL) {
            cls = cls.superclass;
            continue;
        }
        for (unsigned i = 0; i < count; i++) {
            objc_property_t property=properties[i];
            block(property);
        }
        free(properties);
        cls = cls.superclass;
    }
}

- (dispatch_semaphore_t)mapTableSemaphore{
    if (!_mapTableSemaphore) {
       _mapTableSemaphore = dispatch_semaphore_create(1);
    }
    return _mapTableSemaphore;
}

@end
