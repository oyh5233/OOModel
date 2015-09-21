//
//  MUser.h
//  OOModel
//
//  Created by oo on 15/9/21.
//  Copyright © 2015年 comein. All rights reserved.
//

#import "OOModel.h"

@interface MUser : OOModel
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, copy  ) NSString  *nickName;

+ (instancetype)userWithUid:(NSNumber*)uid;
+ (NSArray*)usersWithUids:(NSArray*)uids;

@end
