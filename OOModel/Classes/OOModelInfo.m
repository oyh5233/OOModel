//
//  OOPropertyInfo.m
//  OOModel
//

#import "OOModelInfo.h"
#import "NSObject+OOModel.h"
static OODatabase *oo_global_database=nil;

@interface OOPropertyInfo()

@property (nonatomic,copy  ) NSString           *ivarKey;
@property (nonatomic,copy  ) NSString           *propertyKey;
@property (nonatomic,assign) Class              propertyCls;
@property (nonatomic,assign) Class              ownCls;
@property (nonatomic,assign) OOClassInfo        *propertyClassInfo;
@property (nonatomic,assign) OOClassInfo        *ownClassInfo;
@property (nonatomic,assign) SEL                setter;
@property (nonatomic,assign) SEL                getter;
@property (nonatomic,assign) OOEncodingType     encodingType;
@property (nonatomic,assign) OOPropertyType     propertyType;
@property (nonatomic,assign) ptrdiff_t          ivarOffset;
@property (nonatomic,assign) OOReferenceType    referenceType;
@property (nonatomic,copy  ) id                 jsonKeyPath;
@property (nonatomic,strong) NSValueTransformer *jsonValueTransformer;
@property (nonatomic,strong) NSString           *dbColumn;
@property (nonatomic,strong) NSValueTransformer *dbValueTransformer;
@property (nonatomic,assign) OODbColumnType     dbColumnType;
@property (nonatomic,assign) SEL                jsonForwards;
@property (nonatomic,assign) SEL                jsonBackwards;
@property (nonatomic,assign) SEL                dbForwards;

@end

@interface OOClassInfo ()

@property (nonatomic,assign) Class        cls;

@property (nonatomic,strong) NSArray      *propertyKeys;
@property (nonatomic,strong) NSArray      *propertyInfos;
@property (nonatomic,strong) NSDictionary *propertyInfosByPropertyKeys;

@property (nonatomic,strong) NSArray      *jsonPropertyInfos;

@property (nonatomic,copy  ) NSString     *uniquePropertyKey;

@property (nonatomic,strong) NSArray      *dbPropertyInfos;
@property (nonatomic,assign) BOOL         hasDbColumnType;
@property (nonatomic,copy  ) NSString     *dbTable;
@property (nonatomic,assign) sqlite3_stmt *insertStmt;
@property (nonatomic,assign) sqlite3_stmt *updateStmt;
@property (nonatomic,assign) sqlite3_stmt *uniqueStmt;

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
    self=[self init];
    if (self) {
        self.cls=cls;
        NSMutableDictionary *propertyInfosByPropertyKeys=[NSMutableDictionary dictionary];
        [self enumeratePropertiesUsingBlock:^(objc_property_t property) {
            OOPropertyInfo *propertyInfo=[OOPropertyInfo propertyInfoWithProperty:property ownCls:self.cls];
            if (propertyInfo.ivarKey) {
                propertyInfo =[self initializePropertyInfo:propertyInfo];
                [propertyInfosByPropertyKeys setObject:propertyInfo forKey:propertyInfo.propertyKey];
            }
        }];
        self.propertyInfosByPropertyKeys=propertyInfosByPropertyKeys;
        self.propertyKeys=[self.propertyInfosByPropertyKeys allKeys];
        self.propertyInfos=[self.propertyInfosByPropertyKeys allValues];
        
        if ([cls conformsToProtocol:@protocol(OOJsonModel)]) {
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
            self.jsonPropertyInfos=jsonPropertyInfos;
        }
        
        if ([cls conformsToProtocol:@protocol(OOUniqueModel)]) {
            self.mapTable=[[OOMapTable alloc]initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];;
            self.uniquePropertyKey=[self.cls uniquePropertyKey];
        }
        
        if ([cls conformsToProtocol:@protocol(OODbModel)]) {
            self.hasDbColumnType=[cls respondsToSelector:@selector(dbColumnTypeForPropertyKey:)];
            self.dbTable=OOCOMPACT(NSStringFromClass(self.cls));
            self.database=oo_global_database;
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
            self.dbPropertyInfos=dbPropertyInfos;
        }
        
    }
    return self;
}

- (OOPropertyInfo*)initializePropertyInfo:(OOPropertyInfo*)propertyInfo{
    if (!propertyInfo.ivarKey||(propertyInfo.propertyType&OOPropertyTypeReadonly)) {
        return nil;
    }
    Class cls=self.cls;
    if ([cls conformsToProtocol:@protocol(OOJsonModel)]) {
        NSString *jsonKeyPath=[cls jsonKeyPathsByPropertyKeys][propertyInfo.propertyKey];
        if (jsonKeyPath.length!=0) {
            NSArray *jsonKeyPathArr=[jsonKeyPath componentsSeparatedByString:@"."];
            if (jsonKeyPathArr.count>1) {
                propertyInfo.jsonKeyPath=jsonKeyPathArr;
            }else{
                propertyInfo.jsonKeyPath=jsonKeyPath;
            }
        }
        if ([cls respondsToSelector:@selector(jsonValueTransformerForPropertyKey:)]) {
            propertyInfo.jsonValueTransformer=[self.cls jsonValueTransformerForPropertyKey:propertyInfo.propertyKey];
        }
        if(propertyInfo.encodingType&OOEncodingTypeUnsupportedObject){
            if ([propertyInfo.propertyCls conformsToProtocol:@protocol(OOJsonModel)]) {
                propertyInfo.jsonForwards=@selector(oo_modelWithJson:);
                propertyInfo.jsonBackwards=@selector(oo_jsonDictionary);
            }
        }
    }
    if ([cls conformsToProtocol:@protocol(OODbModel)]) {
        propertyInfo.dbColumn=OOCOMPACT(propertyInfo.propertyKey);
        if ([cls respondsToSelector:@selector(dbValueTransformerForPropertyKey:)]) {
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
        if(propertyInfo.encodingType&OOEncodingTypeUnsupportedObject){
            if ([propertyInfo.propertyCls conformsToProtocol:@protocol(OOUniqueModel)]) {
                propertyInfo.dbForwards=@selector(oo_modelWithUniqueValue:);
            }
        }
    }
    propertyInfo.ownClassInfo=self;
    return propertyInfo;
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
+ (NSLock*)globalLock{
    static NSLock * lock=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock=[[NSLock alloc]init];
    });
    return lock;
}
+ (void)setGlobalDatabase:(OODatabase*)database{
    NSLock *lock=[self globalLock];
    [lock lock];
    if (oo_global_database!=database) {
        oo_global_database=database;
        [oo_global_database open];
    }
    [lock unlock];
}
+ (OODatabase*)globalDatabase{
    NSLock *lock=[self globalLock];
    [lock lock];
    OODatabase *db=oo_global_database;
    [lock unlock];
    return db;
}
@end
