//
//  MUser.h
//  OOModel
//
//  Created by oo on 15/9/20.
//  Copyright © 2015 oo. All rights reserved.
//

#import "OOModel.h"

@interface MUser : OOModel
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, copy  ) NSString  *nickName;

+ (instancetype)userWithUid:(NSNumber*)uid;
+ (NSArray*)usersWithUids:(NSArray*)uids;

@end
