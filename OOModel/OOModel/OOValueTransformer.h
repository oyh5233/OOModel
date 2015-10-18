//
//  OOValueTransformer.h
//  OOModel
//

#import <Foundation/Foundation.h>

typedef id (^OOValueTransformerBlock)(id value);

@interface OOValueTransformer :NSValueTransformer

+ (instancetype)transformerWithForwardBlock:(OOValueTransformerBlock)forwardBlock reverseBlock:(OOValueTransformerBlock)reverseBlock;

- (instancetype)initWithForwardBlock:(OOValueTransformerBlock)forwardBlock reverseBlock:(OOValueTransformerBlock)reverseBlock;

@end
