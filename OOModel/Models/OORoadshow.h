//
//  OORoadshow.h
//  OOModel
//

#import "OOModel.h"
#import "OOUser.h"

@interface OORoadshow : NSObject<OODbModel,OOUniqueModel,OOJsonModel>

@property (nonatomic, assign) NSInteger rid;
@property (nonatomic, copy  ) NSString  *title;
@property (nonatomic, strong) OOUser    *creator;
@property (nonatomic, assign) NSInteger membercount;

@end
