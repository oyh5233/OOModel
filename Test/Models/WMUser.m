//
//  WMUser.m
//  OOModel
//

#import "OOValueTransformer.h"
#import "WMUser.h"
@implementation WMUser
OO_MODEL_IMPLEMENTION_JSON_KEYS(
    OO_PAIR(login, login),
    OO_PAIR(userID, user_id),
    OO_PAIR(avatarURL, meta.avatar_url),
    OO_PAIR(gravatarID, gravatar_id),
    OO_PAIR(htmlURL, html_url),
    OO_PAIR(followersURL, followers_url),
    OO_PAIR(followingURL, following_url),
    OO_PAIR(gistsURL, gists_url),
    OO_PAIR(starredURL, starred_url),
    OO_PAIR(subscriptionsURL, subscriptions_url),
    OO_PAIR(organizationsURL, organizations_url),
    OO_PAIR(reposURL, repos_url),
    OO_PAIR(eventsURL, events_url),
    OO_PAIR(receivedEventsURL, receivedEvents_url),
    OO_PAIR(siteAdmin, site_admin),
    OO_PAIR(publicRepos, public_repos),
    OO_PAIR(publicGists, public_gists),
    OO_PAIR(createdAt, created_at),
    OO_PAIR(updatedAt, updated_at),
    OO_PAIR(type, type),
    OO_PAIR(name, name),
    OO_PAIR(company, company),
    OO_PAIR(blog, blog),
    OO_PAIR(location, location),
    OO_PAIR(email, email),
    OO_PAIR(hireable, hireable),
    OO_PAIR(bio, bio),
    OO_PAIR(followers, followers),
    OO_PAIR(following, following)

        )
OO_MODEL_IMPLEMENTION_UNIQUE(userID)
OO_MODEL_IMPLEMENTION_DB_KEYS(login, userID, avatarURL, gravatarID, htmlURL, followersURL, followingURL, gistsURL, starredURL, subscriptionsURL, organizationsURL, reposURL, eventsURL, receivedEventsURL, siteAdmin, publicRepos, publicGists, createdAt, updatedAt, type, name, company, blog, location, email, hireable, bio, followers, following)

+ (NSValueTransformer *)oo_jsonValueTransformerForPropertyKey:(NSString *)propertyKey
{
    if ([propertyKey isEqualToString:@"test"])
    {
        return [OOValueTransformer transformerWithForwardBlock:^id(id value) {
            return [TestMD oo_modelWithUniqueValue:value];
        }
            reverseBlock:^id(TestMD *value) {
                return @(value.userID);
            }];
    }
    return nil;
}

+ (NSValueTransformer *)oo_dbValueTransformerForPropertyKey:(NSString *)propertyKey
{
    if ([propertyKey isEqualToString:@"test"])
    {
        return [OOValueTransformer transformerWithForwardBlock:^id(id value) {
            return [TestMD oo_modelWithUniqueValue:value];
        }
            reverseBlock:^id(TestMD *value) {
                return @(value.userID);
            }];
    }
    return nil;
}

@end
