//
//  OOMapTable.h
//  OOModel
//
//  Created by oyh on 16/9/25.
//  Copyright © 2016年 oo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OOMapTable : NSMapTable

- (void)inMt:(void(^)(OOMapTable *mt))block;

@end
