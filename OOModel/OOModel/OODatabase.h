//
//  OODatabase.h
//  OOModel
//

#import <Foundation/Foundation.h>

@class OODatabase;

@interface OODatabase : NSObject

@property (nonatomic, strong         ) NSDateFormatter *dateFormatter;
@property (nonatomic, copy  ,readonly) NSString        *file;

+ (instancetype)databaseWithFile:(NSString*)file;

- (instancetype)initWithFile:(NSString*)file;

- (NSArray*)executeQuery:(NSString*)sql arguments:(NSArray*)arguments;

- (BOOL)executeUpdate:(NSString*)sql arguments:(NSArray*)arguments;

- (BOOL)open;

- (BOOL)close;

@end
