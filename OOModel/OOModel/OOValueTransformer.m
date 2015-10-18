//
//  OOValueTransformer.m
//  OOModel
//

#import "OOValueTransformer.h"
#import "objc/runtime.h"
@interface OOValueTransformer ()

@property (nonatomic, copy) OOValueTransformerBlock forwardBlock;
@property (nonatomic, copy) OOValueTransformerBlock reverseBlock;

@end
@implementation OOValueTransformer

#pragma mark --
#pragma mark -- init

+ (instancetype)transformerWithForwardBlock:(OOValueTransformerBlock)forwardBlock reverseBlock:(OOValueTransformerBlock)reverseBlock{
    OOValueTransformer *valueTransformer=[[OOValueTransformer alloc]initWithForwardBlock:forwardBlock reverseBlock:reverseBlock];
    return valueTransformer;
}

- (instancetype)initWithForwardBlock:(OOValueTransformerBlock)forwardBlock reverseBlock:(OOValueTransformerBlock)reverseBlock{
    self=[self init];
    if (self) {
        self.forwardBlock=forwardBlock;
        self.reverseBlock=reverseBlock;
    }
    return self;
}

#pragma mark --
#pragma mark -- override

+ (BOOL)allowsReverseTransformation {
    return YES;
}

+ (Class)transformedValueClass {
    return NSObject.class;
}

- (id)transformedValue:(id)value {
    id result=nil;
    if (self.forwardBlock) {
        result=self.forwardBlock(value);
    }
    return result;
}

- (id)reverseTransformedValue:(id)value {
    id result=nil;
    if (self.reverseBlock) {
        result=self.reverseBlock(value);
    }
    return result;
}

@end
