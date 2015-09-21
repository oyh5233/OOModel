//
//  ViewController.m
//  OOModel
//
//  Created by oo on 15/9/20.
//  Copyright © 2015 oo. All rights reserved.
//

#import "ViewController.h"
#import "CustomTableViewCell.h"
#import "MGroup.h"
static NSString * kString=@"据港媒报道，万人迷“华神”刘德华20日来台参加电影《我的少女时代》感谢影迷活动，受访时，被问到自己的“少男时代”也曾和徐太宇一样叛逆吗？他透露，打架也会打、逃学也逃过，但他觉得那不到使坏程度，只是，他曾被警察局反黑组列入固定约谈名单。华仔解释，当时学校包括他在内有8个同学，警察局的反黑组会固定来学校和他们“聊天”，每年聊一次，“我们也没有做什么，也不是黑帮，他们看不出来谁是真正的黑帮，就找我们！”他也回忆初恋，是中学三年级时，教女同学打排球，然后就和其中一个拍拖了，后来是被甩吗？他装作爱面子地笑回：“只是第一次输！”年轻时很会把妹吗？华仔说，自己就追过那么一个女生，且当时他的长相老成，有个花名“爷爷”，因为他很早就长胡子，会写舞台剧剧本，又很常演爸爸和爷爷，小时候看起来就很老。";
@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *noticeLabel;
@property (nonatomic, strong) UILabel *creatorNameLabel;
@property (nonatomic, strong) UITableView *memebersTableView;
@property (nonatomic, strong) MGroup *group;

@end

@implementation ViewController
- (void)dealloc{
    [self uninstallKVO];
}
- (void)viewDidLoad {
    [super viewDidLoad];

    
    CGFloat width=CGRectGetWidth(self.view.frame);
    CGFloat height=24;
    self.titleLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, 20, width, height)];
    self.noticeLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame), width, height)];
    self.creatorNameLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.noticeLabel.frame), width, height)];
    self.memebersTableView=[[UITableView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.creatorNameLabel.frame),width, CGRectGetHeight(self.view.frame)-CGRectGetMaxY(self.creatorNameLabel.frame)) style:UITableViewStylePlain];
    self.memebersTableView.delegate=self;
    self.memebersTableView.dataSource=self;
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.noticeLabel];
    [self.view addSubview:self.creatorNameLabel];
    [self.view addSubview:self.memebersTableView];
    [self installKVO];

    [OOModel oo_openDatabase:NULL file:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"db.sqlite"] synchronously:YES];
    
    self.group=[[self class]group];
    NSTimer *timer=[[NSTimer alloc]initWithFireDate:[NSDate distantPast] interval:1.0 target:self selector:@selector(change) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
    
    [self.memebersTableView reloadData];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)change{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[self class]changeGroupInfo];
        [[self class]changeMembersInfo];
    });
}
- (void)installKVO{
    [self addObserver:self forKeyPath:@"group.title" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"group.notice" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"group.creator.nickName" options:NSKeyValueObservingOptionNew context:NULL];
}
- (void)uninstallKVO{
    [self removeObserver:self forKeyPath:@"group.title"];
    [self removeObserver:self forKeyPath:@"group.notice"];
    [self removeObserver:self forKeyPath:@"group.creator.nickName"];
}
#pragma mark --
#pragma mark -- 
+ (void)changeGroupInfo{
    [[self class]group];
}
+ (void)changeMembersInfo{
    [[self class]members];
}
+ (MGroup*)group{
    NSMutableDictionary *groupDict=[NSMutableDictionary dictionary];
    [groupDict setObject:@(100) forKey:@"gid"];
    [groupDict setObject:[[self class]randomString:12] forKey:@"title"];
    [groupDict setObject:[[self class]randomString:120] forKey:@"notice"];
    [groupDict setObject:[[self class]userDict:1000] forKey:@"creator"];
    [groupDict setObject:[[self class]memberDicts] forKey:@"members"];
    MGroup *group=[MGroup oo_modelWithDictionary:groupDict];
    return group;
}
+ (NSDictionary*)userDict:(NSInteger)uid{
    return @{
             @"uid":@(uid),
             @"nickName":[[self class] randomString:12]
             };
}
+ (MUser*)user:(NSInteger)uid{
    return [MUser oo_modelWithDictionary:[[self class]userDict:uid]];
}
+ (NSArray*)memberDicts{
    NSMutableArray *array=[NSMutableArray array];
    for(int i=1000;i<1040;i++){
        [array addObject:[[self class]userDict:i]];
    }
    return array;
}
+ (NSArray*)members{
    NSMutableArray *array=[NSMutableArray array];
    for(int i=1000;i<1040;i++){
        [array addObject:[[self class]user:i]];
    }
    return array;
}
+ (NSString*)randomString:(NSInteger)maxLength{
    if (maxLength>kString.length) {
        maxLength=kString.length;
    }
    NSInteger length=arc4random()%maxLength;
    length=length==0?1:length;
    NSMutableString *string=[NSMutableString string];
    for(NSInteger i =0;i<length;i++){
        [string appendString:[kString substringWithRange:NSMakeRange((arc4random()%kString.length),1)]];
    }
    return string;
}
#pragma mark --
#pragma mark -- kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    id value=change[NSKeyValueChangeNewKey];
    if ([value isKindOfClass:[NSNull class]]) {
        value=nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([keyPath isEqualToString:@"group.title"]) {
            self.titleLabel.text=[NSString stringWithFormat:@"title:%@",value];
        }else if ([keyPath isEqualToString:@"group.notice"]){
            self.noticeLabel.text=[NSString stringWithFormat:@"notice:%@",value];
        }else if ([keyPath isEqualToString:@"group.creator.nickName"]){
            self.creatorNameLabel.text=[NSString stringWithFormat:@"creator.nickName:%@",value];
        }
    });
}
#pragma mark --
#pragma mark -- UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.group.members.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 34;
}
- (CustomTableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellId=@"cellId";
    CustomTableViewCell * cell=[tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell=[[CustomTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.user=[self.group.members objectAtIndex:indexPath.row];
    return cell;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
