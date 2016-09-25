//
//  OOMapTable.m
//  OOModel
//
//  Created by oyh on 16/9/25.
//  Copyright © 2016年 oo. All rights reserved.
//

#import "OOMapTable.h"

@interface OOMapTable()
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) void             * queueKey;
@end

@implementation OOMapTable

- (void)inDB:(void(^)(OOMapTable *mt))block{
    if(dispatch_get_specific(self.queueKey)){
        block(self);
    }else{
        dispatch_sync(self.queue,^{
            block(self);
        });
    }
}
@end
