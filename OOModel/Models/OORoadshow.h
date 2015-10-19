//
//  OORoadshow.h
//  OOModel
//
//  Created by oo on 15/10/19.
//  Copyright © 2015年 comein. All rights reserved.
//

#import "OOModel.h"
#import "OOUser.h"
@interface OORoadshow : OOModel

@property (nonatomic, assign) NSInteger rid;
@property (nonatomic, copy  ) NSString  *title;
@property (nonatomic, strong) OOUser    *create;
@property (nonatomic, assign) NSInteger membercount;

@end
