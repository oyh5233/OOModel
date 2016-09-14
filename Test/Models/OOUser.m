//
//  OOUser.m
//  OOModel
//

#import "OOUser.h"

@implementation OOUser

OO_MODEL_IMPLEMENTION_JSON_KEYS(OO_PAIR(uid,id),
                                OO_PAIR(name,name),
                                OO_PAIR(sex,sex),
                                OO_PAIR(age,age)
                                )

OO_MODEL_IMPLEMENTION_UNIQUE(uid)

OO_MODEL_IMPLEMENTION_DB_KEYS(uid,name,sex,age)

@end
