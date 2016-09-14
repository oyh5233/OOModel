//
//  OOModel.h
//  OOModel
//
//  Created by oo on 16/7/13.
//  Copyright © 2016年 oo. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for OOModel.
FOUNDATION_EXPORT double OOModelVersionNumber;

//! Project version string for OOModel.
FOUNDATION_EXPORT const unsigned char OOModelVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OOModel/PublicHeader.h>
#import "NSObject+OOModel.h"
#import "OOModelInfo.h"
#import "OOValueTransformer.h"
#import "OODatabase.h"

#ifndef OO_MODEL_IMPLEMENTION_UNIQUE
#define OO_MODEL_IMPLEMENTION_UNIQUE(x) \
+ (NSString*)uniquePropertyKey{\
return @#x;\
}
#endif
//+ (NSArray*)dbColumnsInPropertyKeys{\
//return [[@#__VA_ARGS__ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@","];\
//}


#ifndef OO_NO_WHITESPACE_NEWLINE
#define OO_NO_WHITESPACE_NEWLINE(x) [x stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
#endif

#ifndef OO_MODEL_IMPLEMENTION_DB_KEYS
#define OO_MODEL_IMPLEMENTION_DB_KEYS(...) \
+ (NSArray*)dbColumnsInPropertyKeys{\
    return [OO_NO_WHITESPACE_NEWLINE(@#__VA_ARGS__) componentsSeparatedByString:@","];\
}
#endif

#ifndef OO_PAIR
#define OO_PAIR(x,y) @#x:@#y
#endif

#ifndef OO_MODEL_IMPLEMENTION_JSON_KEYS
#define OO_MODEL_IMPLEMENTION_JSON_KEYS(...) \
+ (NSDictionary*)jsonKeyPathsByPropertyKeys{\
    return @{\
__VA_ARGS__\
};\
}
#endif