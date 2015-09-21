//
//  CustomTableViewCell.m
//  OOModel
//
//  Created by oo on 15/9/21.
//  Copyright © 2015年 comein. All rights reserved.
//

#import "CustomTableViewCell.h"

@implementation CustomTableViewCell
- (void)dealloc{
    [self unstallKVO];
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self=[super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self installKVO];
    }
    return self;
}
#pragma mark --
#pragma mark -- kvo
- (void)installKVO{
    [self addObserver:self forKeyPath:@"user.nickName" options:NSKeyValueObservingOptionNew context:NULL];
}
- (void)unstallKVO{
    [self removeObserver:self forKeyPath:@"user.nickName"];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"user.nickName"]) {
        id value=change[NSKeyValueChangeNewKey];
        if ([value isKindOfClass:[NSNull class]]) {
            value=nil;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textLabel.text=[NSString stringWithFormat:@"user.nickName:%@",value];
        });
    }
}
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
