//
//  OODatabase.h
//  OOModel
//

#import "sqlite3.h"
#import <Foundation/Foundation.h>
@class OODb;

@interface OODb : NSObject

@property (nonatomic, copy, readonly) NSString *file;

+ (instancetype)dbWithFile:(NSString *)file;

- (instancetype)initWithFile:(NSString *)file;

- (void)syncInDb:(void (^)(OODb *db))block;

- (void)asyncInDb:(void (^)(OODb *db))block;

- (BOOL)executeUpdate:(NSString *)sql arguments:(NSArray *)arguments;

- (BOOL)executeUpdate:(NSString *)sql context:(void *)context stmtBlock:(void (^)(void *context, sqlite3_stmt *stmt, int index))stmtBlock;

- (void)executeQuery:(NSString *)sql context:(void *)context stmtBlock:(void (^)(void *context, sqlite3_stmt *stmt, int index))stmtBlock resultBlock:(void (^)(void *context, sqlite3_stmt *stmt, bool *stop))resultBlock;

- (NSArray *)executeQuery:(NSString *)sql context:(void *)context stmtBlock:(void (^)(void *context, sqlite3_stmt *stmt, int index))stmtBlock;

- (NSArray *)executeQuery:(NSString *)sql arguments:(NSArray *)arguments;

- (void)beginTransaction;

- (void)commit;

@end
