//
//  OODatabase.h
//  OOModel
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"
@class OODatabase;

@interface OODatabase : NSObject

@property (nonatomic, copy, readonly   ) NSString       *file;
@property (nonatomic, assign, readonly ) NSTimeInterval dbTimestamp;

+ (instancetype)databaseWithFile:(NSString*)file;

- (instancetype)initWithFile:(NSString*)file;

- (NSArray*)executeQuery:(NSString*)sql arguments:(NSArray*)arguments;

- (NSArray*)executeQuery:(NSString*)sql arguments:(NSArray*)arguments disableUseDbQueue:(BOOL)autoUseDbQueue;

- (BOOL)executeUpdate:(NSString*)sql arguments:(NSArray*)arguments;

- (BOOL)executeUpdate:(NSString*)sql arguments:(NSArray*)arguments disableUseDbQueue:(BOOL)disableUseDbQueue;

- (BOOL)open;

- (BOOL)close;

- (BOOL)beginTransaction;

- (BOOL)rollback;

- (BOOL)commit;

- (void)inDB:(void(^)(OODatabase *db))block;

@end
