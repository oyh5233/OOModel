//
//  OOMapTable.h
//  OOModel
//
//  Created by oyh on 16/9/25.
//  Copyright © 2016年 oo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OOMapTable : NSObject

- (instancetype)initWithKeyOptions:(NSPointerFunctionsOptions)keyOptions valueOptions:(NSPointerFunctionsOptions)valueOptions capacity:(NSUInteger)initialCapacity;

- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (void)syncInMt:(void(^)(OOMapTable *mt))block;
- (void)asyncInMt:(void(^)(OOMapTable *mt))block;

@end
