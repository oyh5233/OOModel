//
//  OOMapTable.m
//  OOModel
//
//  Created by oyh on 16/9/25.
//  Copyright © 2016年 oo. All rights reserved.
//

#import "OOMapTable.h"

@interface OOMapTable()
@property (nonatomic, strong) NSMapTable       *mapTable;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) void             * queueKey;
@end

@implementation OOMapTable
- (instancetype)init{
    self=[super init];
    if (self) {
        self.queue=dispatch_queue_create("cn.comein.map_table", NULL);
        self.queueKey=&_queueKey;
        dispatch_queue_set_specific(self.queue, self.queueKey, (__bridge void *)self, NULL);
    }
    return self;
}

- (instancetype)initWithKeyOptions:(NSPointerFunctionsOptions)keyOptions valueOptions:(NSPointerFunctionsOptions)valueOptions capacity:(NSUInteger)initialCapacity{
    self=[self init];
    if (self) {
        self.mapTable=[[NSMapTable alloc] initWithKeyOptions:keyOptions valueOptions:valueOptions capacity:initialCapacity];
    }
    return self;
}

- (id)objectForKey:(id)key{
    return [self.mapTable objectForKey:key];
}

- (void)setObject:(id)object forKey:(id)key{
    [self.mapTable setObject:object forKey:key];
}

- (void)removeObjectForKey:(id)key{
    [self.mapTable removeObjectForKey:key];
}

- (void)syncInMt:(void(^)(OOMapTable *mt))block{
    if(dispatch_get_specific(self.queueKey)){
        block(self);
    }else{
        dispatch_sync(self.queue,^{
            block(self);
        });
    }
}
- (void)asyncInMt:(void(^)(OOMapTable *mt))block{
    if(dispatch_get_specific(self.queueKey)){
        block(self);
    }else{
        dispatch_async(self.queue,^{
            block(self);
        });
    }
}

@end
