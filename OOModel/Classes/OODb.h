//
//  OODatabase.h
//  OOModel
//

#import "sqlite3.h"
#import <Foundation/Foundation.h>

@interface OODb : NSObject

@property (nonatomic, copy, readonly) NSString *file;

+ (instancetype)dbWithFile:(NSString *)file;

- (instancetype)initWithFile:(NSString *)file;

- (void)syncInDb:(void (^)(OODb *db))block;

- (void)asyncInDb:(void (^)(OODb *db))block;

- (BOOL)executeUpdate:(NSString *)sql arguments:(NSArray *)arguments;

- (BOOL)executeUpdate:(NSString *)sql stmtBlock:(void (^)(sqlite3_stmt *stmt, int dix))stmtBlock;

- (void)executeQuery:(NSString *)sql stmtBlock:(void (^)(sqlite3_stmt *stmt, int idx))stmtBlock resultBlock:(void (^)(sqlite3_stmt *stmt, bool *stop))resultBlock;

- (NSArray *)executeQuery:(NSString *)sql stmtBlock:(void (^)(sqlite3_stmt *stmt, int idx))stmtBlock;

- (NSArray *)executeQuery:(NSString *)sql arguments:(NSArray *)arguments;

- (void)beginTransaction;

- (void)commit;

@end
