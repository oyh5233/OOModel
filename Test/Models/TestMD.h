//
//  TestMD.h
//  Demo
//
//  Created by ouyanghua on 16/3/24.
//  Copyright © 2016年 oo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OOModel.h"
@interface TestMD : NSObject<OOJsonModel,OOUniqueModel,OODbModel>
@property (assign) UInt64   userID;

@end
