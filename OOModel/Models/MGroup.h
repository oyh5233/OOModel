//
//  MGroup.h
//  OOModel
//
//  Created by oo on 15/9/20.
//  Copyright © 2015 oo. All rights reserved.
//

#import "OOModel.h"
#import "MUser.h"
@interface MGroup : OOModel
@property (nonatomic, assign) NSInteger gid;
@property (nonatomic, copy  ) NSString  *title;
@property (nonatomic, copy  ) NSString  *notice;
@property (nonatomic, strong) MUser      *creator;
@property (nonatomic, strong) NSArray   *members;

@end
