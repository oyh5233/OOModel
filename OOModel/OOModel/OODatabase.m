//
//  OODatabase.m
//  OOModel
//

#import "OODatabase.h"
#import "sqlite3.h"
#import "OOModel.h"
@interface OODatabase ()

@property (nonatomic, copy  ) NSString         *file;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) void             *queueKey;
@property (nonatomic, assign) sqlite3          *database;

@end

@implementation OODatabase
#pragma mark --
#pragma mark -- init

+ (instancetype)databaseWithFile:(NSString *)file{
    return [[self alloc]initWithFile:file];
}

- (instancetype)initWithFile:(NSString *)file{
    self=[self init];
    if (self) {
        self.file=file;
    }
    return self;
}

- (instancetype)init{
    self=[super init];
    if (self) {
        self.queue=dispatch_queue_create("OOModelDatabaseQueue", NULL);
        self.queueKey=&_queueKey;
        dispatch_queue_set_specific(self.queue, self.queueKey, (__bridge void *)self, NULL);
    }
    return self;
}

#pragma mark --
#pragma mark -- in database

- (void)_inDatabase:(void (^)(OODatabase * db))block{
    if (!block) {
        return;
    }
    if (dispatch_get_specific(self.queueKey)) {
        block(self);
    }else{
        dispatch_sync(self.queue, ^{
            block(self);
        });
    }
}

#pragma mark --
#pragma mark -- open and close

- (BOOL)open{
    __block BOOL ret;
    [self _inDatabase:^(OODatabase *db) {
        [db close];
        sqlite3 *database=db.database;
        int result=sqlite3_open([self.file cStringUsingEncoding:NSUTF8StringEncoding], &database);
//        int result=sqlite3_open_v2([self.file UTF8String], &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE, NULL);
        if (result != SQLITE_OK) {
            OOModelLog(@"%@",[self _lastError]);
            ret=NO;
        }else{
            ret=YES;
            db.database=database;
        }
    }];
    return ret;
}

- (BOOL)close{
    __block BOOL ret;
    [self _inDatabase:^(OODatabase *db) {
        if (db) {
            int result = sqlite3_close(db.database);
            if (result != SQLITE_OK) {
                OOModelLog(@"%@",[db _lastError]);
                ret=NO;
            }else{
                ret=YES;
                db.database = nil;
            }
        }else{
            ret=YES;
        }
    }];
    return ret;
}

#pragma mark --
#pragma mark -- query

- (NSArray*)executeQuery:(NSString*)sql arguments:(NSArray*)arguments{
    __block NSMutableArray *sets  = nil;
    [self _inDatabase:^(OODatabase *db) {
        NSParameterAssert(db.database);
        sqlite3_stmt *stmt = NULL;
        if (arguments&&![arguments isKindOfClass:NSArray.class]) {
            OOModelLog(@"arguments is not a array!");
            return;
        }
        int result = sqlite3_prepare_v2(db.database, [sql UTF8String], -1, &stmt, 0);
        if (result != SQLITE_OK) {
            sqlite3_finalize(stmt);
            OOModelLog(@"%@",[db _lastError]);
            return;
        }
        int index=0;
        id  obj=nil;
        int parameterCount = sqlite3_bind_parameter_count(stmt);
        if (parameterCount != arguments.count) {
            sqlite3_finalize(stmt);
            OOModelLog(@"arguments's count is not equal to parameter's count!");
            return;
        }
        sets=[NSMutableArray array];
        while (index < parameterCount) {
            obj = [arguments objectAtIndex:index];
            index++;
            [db _bindObject:obj toColumn:index inStatement:stmt];
        }
        while (YES) {
            result = sqlite3_step(stmt);
            if (result == SQLITE_ROW) {
                int dataCount = sqlite3_data_count(stmt);
                NSDictionary *resultDictionary = [db _dictionaryInStmt:stmt count:dataCount];
                if (resultDictionary.count>0) {
                    [sets addObject:resultDictionary];
                }
            }else{
                break;
            }
        }
        sqlite3_finalize(stmt);
    }];
    return sets;
}

#pragma mark --
#pragma mark -- update

- (BOOL)executeUpdate:(NSString*)sql arguments:(NSArray*)arguments{
    __block BOOL ret;
    [self _inDatabase:^(OODatabase *db) {
        sqlite3_stmt *stmt = NULL;
        int result = sqlite3_prepare_v2(db.database, [sql UTF8String], -1, &stmt, 0);
        if (result != SQLITE_OK) {
            sqlite3_finalize(stmt);
            OOModelLog(@"%@",[db _lastError]);
            ret = NO;
            return;
        }
        int index=0;
        id obj=nil;
        int parameterCount = sqlite3_bind_parameter_count(stmt);
        if (parameterCount != arguments.count) {
            sqlite3_finalize(stmt);
            OOModelLog(@"arguments's count is not equal to parameter's count!");
            ret=NO;
            return;
        }
        while(index < parameterCount) {
            obj = [arguments objectAtIndex:index];
            index++;
            [self _bindObject:obj toColumn:index inStatement:stmt];
        }
        result = sqlite3_step(stmt);
        if (result != SQLITE_DONE) {
            OOModelLog(@"%@",[self _lastError]);
            ret=NO;
        }else{
            ret=YES; 
        }
        sqlite3_finalize(stmt);
    }];
    return ret;
}

#pragma mark --
#pragma mark -- bind object to column

- (void)_bindObject:(id)obj toColumn:(int)index inStatement:(sqlite3_stmt*)stmt {
    int result=SQLITE_OK;
    if ((!obj) || ((NSNull *)obj == [NSNull null])) {
        result = sqlite3_bind_null(stmt, index);
    }else if ([obj isKindOfClass:NSData.class]) {
        const void *bytes = [obj bytes];
        if (!bytes) {
            bytes = "";
        }
        result = sqlite3_bind_blob(stmt, index, bytes, (int)[obj length], SQLITE_STATIC);
    }else if ([obj isKindOfClass:NSDate.class]) {
        if (self.dateFormatter) {
            result = sqlite3_bind_text(stmt, index, [[self.dateFormatter stringFromDate:obj] UTF8String], -1, SQLITE_STATIC);
        }else{
            result = sqlite3_bind_double(stmt, index, [obj timeIntervalSince1970]);
        }
    }else if ([obj isKindOfClass:NSNumber.class]) {
        if (strcmp([obj objCType], @encode(char)) == 0) {
            result = sqlite3_bind_int(stmt, index, [obj charValue]);
        }else if (strcmp([obj objCType], @encode(unsigned char)) == 0) {
            result = sqlite3_bind_int(stmt, index, [obj unsignedCharValue]);
        }else if (strcmp([obj objCType], @encode(short)) == 0) {
            result = sqlite3_bind_int(stmt, index, [obj shortValue]);
        }else if (strcmp([obj objCType], @encode(unsigned short)) == 0) {
            result = sqlite3_bind_int(stmt, index, [obj unsignedShortValue]);
        }else if (strcmp([obj objCType], @encode(int)) == 0) {
            result = sqlite3_bind_int(stmt, index, [obj intValue]);
        }else if (strcmp([obj objCType], @encode(unsigned int)) == 0) {
            result = sqlite3_bind_int64(stmt, index, (long long)[obj unsignedIntValue]);
        }else if (strcmp([obj objCType], @encode(long)) == 0) {
            result = sqlite3_bind_int64(stmt, index, [obj longValue]);
        }else if (strcmp([obj objCType], @encode(unsigned long)) == 0) {
            result = sqlite3_bind_int64(stmt, index, (long long)[obj unsignedLongValue]);
        }else if (strcmp([obj objCType], @encode(long long)) == 0) {
            result = sqlite3_bind_int64(stmt, index, [obj longLongValue]);
        }else if (strcmp([obj objCType], @encode(unsigned long long)) == 0) {
            result = sqlite3_bind_int64(stmt, index, (long long)[obj unsignedLongLongValue]);
        }else if (strcmp([obj objCType], @encode(float)) == 0) {
            result = sqlite3_bind_double(stmt, index, [obj floatValue]);
        }else if (strcmp([obj objCType], @encode(double)) == 0) {
            result = sqlite3_bind_double(stmt, index, [obj doubleValue]);
        }else if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            result = sqlite3_bind_int(stmt, index, ([obj boolValue] ? 1 : 0));
        }else{
            result = sqlite3_bind_text(stmt, index, [[obj description] UTF8String], -1, SQLITE_STATIC);
        }
    }else{
            result = sqlite3_bind_text(stmt, index, [[obj description] UTF8String], -1, SQLITE_STATIC);
    }
    if (result!=SQLITE_OK) {
        OOModelLog(@"%@",[self _lastError]);
    }
}
#pragma mark --
#pragma mark -- getter

- (NSDictionary*)_dictionaryInStmt:(sqlite3_stmt*)stmt count:(int)count{
    NSMutableDictionary *set=[NSMutableDictionary dictionary];
    for (int index = 0; index < count; index++) {
        NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(stmt, index)];
        int type = sqlite3_column_type(stmt, index);
        id value = nil;
        if (type == SQLITE_INTEGER) {
            value = [NSNumber numberWithLongLong:sqlite3_column_int64(stmt,index)];
        }else if (type == SQLITE_FLOAT) {
            value = [NSNumber numberWithDouble:sqlite3_column_double(stmt,index)];
        }else if (type == SQLITE_BLOB) {
            int bytes=sqlite3_column_bytes(stmt,index);
            value = [NSData dataWithBytes:sqlite3_column_blob(stmt, index) length:bytes];
        }else if (type == SQLITE_NULL) {
            continue;
        }else{
            value = [[NSString alloc]initWithCString:(const char *)sqlite3_column_text(stmt,index) encoding:NSUTF8StringEncoding];
        }
        if (value == nil || [value isKindOfClass:NSNull.class]) {
            continue;
        }
        [set setObject:value forKey:columnName];
    }
    return set;
}

- (NSError*)_lastError{
    return [NSError errorWithDomain:NSStringFromClass(self.class) code:sqlite3_errcode(self.database) userInfo:@{NSLocalizedDescriptionKey:[[NSString alloc]initWithCString:sqlite3_errmsg(self.database) encoding:NSUTF8StringEncoding]}];
}

@end
