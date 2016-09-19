//
//  TestMD.m
//  Demo
//
//

#import "TestMD.h"

@implementation TestMD


OO_MODEL_IMPLEMENTION_JSON_KEYS(OO_PAIR(userID, id))
OO_MODEL_IMPLEMENTION_UNIQUE(userID)
OO_MODEL_IMPLEMENTION_DB_KEYS(userID)

@end
