//
//  OOUser.h
//  OOModel
//

#import "OOModel.h"
typedef NS_ENUM(NSInteger,UserSex) {
    UserSexMan,
    UserSexWoman
};
@interface OOUser : OOModel <OODatabaseSerializing,OOJsonSerializing,OOManagerSerializing>
@property (nonatomic, assign)NSInteger uid;
@property (nonatomic, copy  )NSString *name;
@property (nonatomic, assign)NSInteger sex;
@property (nonatomic, assign)NSInteger age;
@end
