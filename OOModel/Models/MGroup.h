//
//  Group.h
//  OOModel
//
//  Created by oo on 15/9/21.
//  Copyright © 2015年 comein. All rights reserved.
//

#import "OOModel.h"
#import "User.h"
@interface MGroup : OOModel
@property (nonatomic, assign) NSInteger gid;
@property (nonatomic, copy  ) NSString  *title;
@property (nonatomic, copy  ) NSString  *notice;
@property (nonatomic, strong) User      *creator;
@property (nonatomic, strong) NSArray   *members;

@end
