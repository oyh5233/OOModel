//
//  WMUser.h
//  OOModel
//


#import <Foundation/Foundation.h>
#import "OOModel.h"
#import "TestMD.h"
typedef NS_ENUM(NSInteger,WMUserSex) {
    WMUserSexUnknow,
    WMUserSexMan,
    WMUserSexWoman
};
@interface WMUser : NSObject<OOUniqueModel,OODbModel,OOJsonModel>
@property (strong) NSString *login;
@property (assign) UInt64   userID;
@property (strong) NSString *avatarURL;
@property (strong) NSString *gravatarID;
@property (strong) NSString *url;
@property (strong) NSString *htmlURL;
@property (strong) NSString *followersURL;
@property (strong) NSString *followingURL;
@property (strong) NSString *gistsURL;
@property (strong) NSString *starredURL;
@property (strong) NSString *subscriptionsURL;
@property (strong) NSString *organizationsURL;
@property (strong) NSString *reposURL;
@property (strong) NSString *eventsURL;
@property (strong) NSString *receivedEventsURL;
@property (strong) NSString *type;
@property (assign) BOOL     siteAdmin;
@property (strong) NSString *name;
@property (strong) NSString *company;
@property (strong) NSString *blog;
@property (strong) NSString *location;
@property (strong) NSString *email;
@property (strong) NSString *hireable;
@property (strong) NSString *bio;
@property (assign) UInt32   publicRepos;
@property (assign) UInt32   publicGists;
@property (assign) UInt32   followers;
@property (assign) UInt32   following;
@property (strong) NSDate   *createdAt;
@property (strong) NSDate   *updatedAt;
@property (strong) TestMD   *test;

@end
