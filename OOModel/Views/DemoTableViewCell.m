//
//  DemoTableViewCell.m
//  OOModel
//

#import "DemoTableViewCell.h"

@interface DemoTableViewCell ()

@property (nonatomic, strong)IBOutlet UILabel *titleLabel;
@property (nonatomic, strong)IBOutlet UILabel *countLabel;
@property (nonatomic, strong)IBOutlet UILabel *nameLabel;
@property (nonatomic, strong)IBOutlet UILabel *sexLabel;
@property (nonatomic, strong)IBOutlet UILabel *ageLabel;
@property (nonatomic, strong)IBOutlet UILabel *ridLabel;
@property (nonatomic, strong)IBOutlet UILabel *uidLabel;

@end

@implementation DemoTableViewCell

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"roadshow.title"];
    [self removeObserver:self forKeyPath:@"roadshow.membercount"];
    [self removeObserver:self forKeyPath:@"roadshow.rid"];
    [self removeObserver:self forKeyPath:@"roadshow.creator.name"];
    [self removeObserver:self forKeyPath:@"roadshow.creator.sex"];
    [self removeObserver:self forKeyPath:@"roadshow.creator.age"];
    [self removeObserver:self forKeyPath:@"roadshow.creator.uid"];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)awakeFromNib {
    // Initialization code
    [self addObserver:self forKeyPath:@"roadshow.title" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"roadshow.membercount" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"roadshow.rid" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"roadshow.creator.name" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"roadshow.creator.sex" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"roadshow.creator.age" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"roadshow.creator.uid" options:NSKeyValueObservingOptionNew context:NULL];


}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)valueDidChange:(NSDictionary*)change{
    NSString *keyPath=change[@"keyPath"];
    id value=change[@"value"];
    if ([keyPath isEqualToString:@"roadshow.title"]) {
        self.titleLabel.text=[NSString stringWithFormat:@"title:%@",value];
    }else if ([keyPath isEqualToString:@"roadshow.membercount"]) {
        self.countLabel.text=[NSString stringWithFormat:@"count:%@",value];
    }else if ([keyPath isEqualToString:@"roadshow.creator.name"]) {
        self.nameLabel.text=[NSString stringWithFormat:@"name:%@",value];
    }else if ([keyPath isEqualToString:@"roadshow.creator.sex"]) {
        self.sexLabel.text=[NSString stringWithFormat:@"sex:%@",value];
    }else if ([keyPath isEqualToString:@"roadshow.creator.age"]) {
        self.ageLabel.text=[NSString stringWithFormat:@"age:%@",value];
    }else if ([keyPath isEqualToString:@"roadshow.rid"]) {
        self.ridLabel.text=[NSString stringWithFormat:@"rid:%@",value];
    }else if ([keyPath isEqualToString:@"roadshow.creator.uid"]) {
        self.uidLabel.text=[NSString stringWithFormat:@"uid:%@",value];
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    id value=change[NSKeyValueChangeNewKey];
    if (!value||[value isKindOfClass:NSNull.class]) {
        return;
    }
    [self performSelectorOnMainThread:@selector(valueDidChange:) withObject:@{@"keyPath":keyPath,@"value":value} waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
}




@end
