//
//  OODatabase.m
//  OOModel
//

#import "OODb.h"
#ifndef OODB_LOG
#define OODB_LOG(code, db) _log(__LINE__, code, sqlite3_errmsg(db))
#endif

static inline int _log(int line, int code, const char *desc)
{
    if (code != SQLITE_DONE && code != SQLITE_OK && code != SQLITE_ROW)
    {
        printf("\n%d: %d,%s", line, code, desc);
    }
    return code;
}

@interface OOStmt : NSObject

@property (nonatomic, assign) sqlite3_stmt *stmt;
@property (nonatomic, copy) NSString *sql;

@end

@implementation OOStmt

- (void)dealloc
{
    if (self.stmt)
    {
        sqlite3_finalize(self.stmt);
    }
}

@end

@interface OODb ()

@property (nonatomic, copy) NSString *file;
@property (nonatomic, assign) sqlite3 *db;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) void *queueKey;
@property (nonatomic, assign) UInt64 transactionReferenceCount;
@property (nonatomic, strong) NSMutableDictionary *stmts;

@end

@implementation OODb

- (void)syncInDb:(void (^)(OODb *db))block
{
    if (dispatch_get_specific(self.queueKey))
    {
        block(self);
    }
    else
    {
        dispatch_sync(self.queue, ^{
            block(self);
        });
    }
}

- (void)asyncInDb:(void (^)(OODb *db))block
{
    if (dispatch_get_specific(self.queueKey))
    {
        block(self);
    }
    else
    {
        dispatch_async(self.queue, ^{
            block(self);
        });
    }
}

#pragma mark--
#pragma mark-- init
- (void)dealloc
{
    [self removeAllStmt];
    if (self.db)
    {
        sqlite3_close(self.db);
    }
}

+ (instancetype)dbWithFile:(NSString *)file
{
    return [[self alloc] initWithFile:file];
}

- (instancetype)initWithFile:(NSString *)file
{
    self = [self init];
    if (self)
    {
        self.file = file;
        [self open];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.transactionReferenceCount = 0;
        self.queue = dispatch_queue_create("com.code4god.OOModel.OODb", NULL);
        self.queueKey = &_queueKey;
        dispatch_queue_set_specific(self.queue, self.queueKey, (__bridge void *) self, NULL);
        self.stmts = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark--
#pragma mark-- open and close

- (BOOL)open
{
    sqlite3 *db;
    if (OODB_LOG(sqlite3_open([self.file cStringUsingEncoding:NSUTF8StringEncoding], &db), self.db) != SQLITE_OK)
    {
        return NO;
    }
    self.db = db;
    return YES;
}

- (BOOL)close
{
    if (self.db)
    {
        if (OODB_LOG(sqlite3_close(self.db), self.db) != SQLITE_OK)
        {
            return NO;
        }
        self.db = nil;
    }
    return YES;
}

#pragma mark--
#pragma mark-- stmt
- (sqlite3_stmt *)stmtForSql:(NSString *)sql
{
    OOStmt *s = self.stmts[sql];
    if (!s)
    {
        sqlite3_stmt *stmt = NULL;
        if (OODB_LOG(sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &stmt, 0), self.db) != SQLITE_OK)
        {
            sqlite3_finalize(stmt);
            return NULL;
        }
        s = [[OOStmt alloc] init];
        s.stmt = stmt;
        s.sql = sql;
        self.stmts[sql] = s;
    }
    sqlite3_clear_bindings(s.stmt);
    sqlite3_reset(s.stmt);
    return s.stmt;
}

- (void)removeStmtForSql:(NSString *)sql
{
    OOStmt *s = self.stmts[sql];
    if (s.stmt)
    {
        sqlite3_finalize(s.stmt);
    }
    [self.stmts removeObjectForKey:sql];
}

- (void)removeAllStmt
{
    [self.stmts enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, OOStmt *_Nonnull obj, BOOL *_Nonnull stop) {
        if (obj.stmt)
        {
            sqlite3_finalize(obj.stmt);
        }
    }];
    [self.stmts removeAllObjects];
}
#pragma mark--
#pragma mark-- query

- (NSArray *)executeQuery:(NSString *)sql arguments:(NSArray *)arguments
{
    return [self executeQuery:sql context:NULL stmtBlock:^(void *context, sqlite3_stmt *stmt, int index) {
        [self _bindObject:arguments[index-1] toColumn:index inStatement:stmt];
    }];
}

- (NSArray *)executeQuery:(NSString *)sql context:(void *)context stmtBlock:(void (^)(void *context, sqlite3_stmt *stmt, int index))stmtBlock
{
    __block NSMutableArray *array = [NSMutableArray array];
    [self executeQuery:sql context:context stmtBlock:stmtBlock resultBlock:^(void *context, sqlite3_stmt *stmt, bool *stop) {
        int count = sqlite3_data_count(stmt);
        NSDictionary *dictionary = [self _dictionaryInStmt:stmt count:count];
        if (dictionary.count > 0)
        {
            [array addObject:dictionary];
        }
    }];
    return array.count ? array : nil;
}

- (void)executeQuery:(NSString *)sql context:(void *)context stmtBlock:(void (^)(void *context, sqlite3_stmt *stmt, int index))stmtBlock resultBlock:(void (^)(void *context, sqlite3_stmt *stmt, bool *stop))resultBlock
{
    NSParameterAssert(stmtBlock);
    NSParameterAssert(resultBlock);
    sqlite3_stmt *stmt = [self stmtForSql:sql];
    if (!stmt)
    {
        return;
    }
    int count = sqlite3_bind_parameter_count(stmt);
    for (int i = 0; i < count; i++)
    {
        stmtBlock(context, stmt, i+1);
    }
    bool stop = NO;
    while (OODB_LOG(sqlite3_step(stmt), self.db) == SQLITE_ROW)
    {
        resultBlock(context, stmt, &stop);
        if (stop)
        {
            return;
        }
    }
}

#pragma mark--
#pragma mark-- update

- (BOOL)executeUpdate:(NSString *)sql arguments:(NSArray *)arguments
{
    return [self executeUpdate:sql context:NULL stmtBlock:^(void *context, sqlite3_stmt *stmt, int index) {
        [self _bindObject:arguments[index-1] toColumn:index inStatement:stmt];
    }];
}

- (BOOL)executeUpdate:(NSString *)sql context:(void *)context stmtBlock:(void (^)(void *context, sqlite3_stmt *stmt, int index))stmtBlock
{
    NSParameterAssert(stmtBlock);
    sqlite3_stmt *stmt = [self stmtForSql:sql];
    if (!stmt)
    {
        return NO;
    }
    int count = sqlite3_bind_parameter_count(stmt);
    for (int i = 0; i < count; i++)
    {
        stmtBlock(context, stmt, i+1);
    }
    if (OODB_LOG(sqlite3_step(stmt), self.db) != SQLITE_DONE)
    {
        return NO;
    }
    return YES;
}

#pragma mark--
#pragma mark--transaction

- (void)beginTransaction
{
    self.transactionReferenceCount++;
    if (self.transactionReferenceCount == 1)
    {
        [self executeUpdate:@"begin exclusive transaction" arguments:nil];
    }
}
//[self executeUpdate:@"rollback transaction" arguments:nil];
- (void)commit
{
    if (self.transactionReferenceCount > 0)
    {
        self.transactionReferenceCount--;
        if (self.transactionReferenceCount == 0)
        {
            [self executeUpdate:@"commit transaction" arguments:nil];
        }
    }
}

#pragma mark--
#pragma mark-- bind object to column

- (void)_bindObject:(id)obj toColumn:(int)index inStatement:(sqlite3_stmt *)stmt
{
    int result = SQLITE_OK;
    if ((!obj) || obj == (id) kCFNull)
    {
        result = sqlite3_bind_null(stmt, index);
    }
    else if ([obj isKindOfClass:NSData.class])
    {
        const void *bytes = [obj bytes];
        if (!bytes)
        {
            bytes = "";
        }
        result = sqlite3_bind_blob(stmt, index, bytes, (int) [obj length], SQLITE_STATIC);
    }
    else if ([obj isKindOfClass:NSDate.class])
    {
        result = sqlite3_bind_double(stmt, index, [obj timeIntervalSince1970]);
    }
    else if ([obj isKindOfClass:NSNumber.class])
    {
        if (strcmp([obj objCType], @encode(char)) == 0)
        {
            result = sqlite3_bind_int(stmt, index, [obj charValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned char)) == 0)
        {
            result = sqlite3_bind_int(stmt, index, [obj unsignedCharValue]);
        }
        else if (strcmp([obj objCType], @encode(short)) == 0)
        {
            result = sqlite3_bind_int(stmt, index, [obj shortValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned short)) == 0)
        {
            result = sqlite3_bind_int(stmt, index, [obj unsignedShortValue]);
        }
        else if (strcmp([obj objCType], @encode(int)) == 0)
        {
            result = sqlite3_bind_int(stmt, index, [obj intValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned int)) == 0)
        {
            result = sqlite3_bind_int64(stmt, index, (long long) [obj unsignedIntValue]);
        }
        else if (strcmp([obj objCType], @encode(long)) == 0)
        {
            result = sqlite3_bind_int64(stmt, index, [obj longValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long)) == 0)
        {
            result = sqlite3_bind_int64(stmt, index, (long long) [obj unsignedLongValue]);
        }
        else if (strcmp([obj objCType], @encode(long long)) == 0)
        {
            result = sqlite3_bind_int64(stmt, index, [obj longLongValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long long)) == 0)
        {
            result = sqlite3_bind_int64(stmt, index, (long long) [obj unsignedLongLongValue]);
        }
        else if (strcmp([obj objCType], @encode(float)) == 0)
        {
            result = sqlite3_bind_double(stmt, index, [obj floatValue]);
        }
        else if (strcmp([obj objCType], @encode(double)) == 0)
        {
            result = sqlite3_bind_double(stmt, index, [obj doubleValue]);
        }
        else if (strcmp([obj objCType], @encode(BOOL)) == 0)
        {
            result = sqlite3_bind_int(stmt, index, ([obj boolValue] ? 1 : 0));
        }
        else
        {
            result = sqlite3_bind_text(stmt, index, [[obj description] UTF8String], -1, SQLITE_STATIC);
        }
    }
    else
    {
        result = sqlite3_bind_text(stmt, index, [[obj description] UTF8String], -1, SQLITE_STATIC);
    }
    OODB_LOG(result, self.db);
}
#pragma mark--
#pragma mark-- getter

- (NSDictionary *)_dictionaryInStmt:(sqlite3_stmt *)stmt count:(int)count
{
    NSMutableDictionary *set = [NSMutableDictionary dictionary];
    for (int index = 0; index < count; index++)
    {
        NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(stmt, index)];
        int type = sqlite3_column_type(stmt, index);
        id value = nil;
        if (type == SQLITE_INTEGER)
        {
            value = [NSNumber numberWithLongLong:sqlite3_column_int64(stmt, index)];
        }
        else if (type == SQLITE_FLOAT)
        {
            value = [NSNumber numberWithDouble:sqlite3_column_double(stmt, index)];
        }
        else if (type == SQLITE_BLOB)
        {
            int bytes = sqlite3_column_bytes(stmt, index);
            value = [NSData dataWithBytes:sqlite3_column_blob(stmt, index) length:bytes];
        }
        else if (type == SQLITE_NULL)
        {
            continue;
        }
        else
        {
            value = [[NSString alloc] initWithCString:(const char *) sqlite3_column_text(stmt, index) encoding:NSUTF8StringEncoding];
        }
        if (value == nil || [value isKindOfClass:NSNull.class])
        {
            continue;
        }
        [set setObject:value forKey:columnName];
    }
    return set;
}

- (NSError *)_lastError
{
    return [NSError errorWithDomain:NSStringFromClass(self.class) code:sqlite3_errcode(self.db) userInfo:@{NSLocalizedDescriptionKey: [[NSString alloc] initWithCString:sqlite3_errmsg(self.db) encoding:NSUTF8StringEncoding]}];
}

@end
