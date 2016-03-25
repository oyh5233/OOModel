//
//  ViewController.m
//  OOModel
//

#import "ViewController.h"
#import "OORoadshow.h"
#import "DemoTableViewCell.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray * roadshows;
@property (nonatomic, strong) UITableView    *tableView;

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [OORoadshow oo_openDb:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"db.sqlite"]];
    for (int i = 0; i < 3 ; i++){
        NSDictionary *jsonDictionary=@{
                                       @"id":[NSString stringWithFormat:@"%d",i+1],
                                       @"extra":@{
                                               @"creator":@{
                                                       @"id":i<2?[NSString stringWithFormat:@"%d",1]:[NSString stringWithFormat:@"%d",2]
                                                       }
                                               }
                                       };
        
        OORoadshow *roadshow=[OORoadshow oo_modelWithJson:jsonDictionary];
        [self.roadshows addObject:roadshow];
    }
    [self.view addSubview:self.tableView];
    NSTimer *timer1=[NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(timer1) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:timer1 forMode:NSRunLoopCommonModes];
    [timer1 fire];
    NSTimer *timer11=[NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(timer1) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:timer11 forMode:NSRunLoopCommonModes];
    [timer11 fire];
    NSTimer *timer2=[NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(timer2) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:timer2 forMode:NSRunLoopCommonModes];
    [timer2 fire];
    NSTimer *timer22=[NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(timer2) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:timer22 forMode:NSRunLoopCommonModes];
    [timer22 fire];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)timer1{
    void (^block)()=^{
        NSString *str=@"Oprah takes a huge gamble on weight loss giant Amazon slaps some of its users with lawsuit New Orleans ranks No. 1 on the list for jobs in this field 7 things to try out before deciding to retire from work Cuban shares the advice that made him a success";
        int location=arc4random()%str.length-1;
        location=location<0?0:location;
        int length=arc4random()%((str.length-location-1))+1;
        NSString *title=[str substringWithRange:NSMakeRange(location, length)];
  

        NSString *rid=[NSString stringWithFormat:@"%d",arc4random()%3+1];
        NSString *membercount=[NSString stringWithFormat:@"%d",arc4random()%98+1];
        NSDictionary *roadshowDict=@{@"id":rid,@"membercount":membercount,@"title":title};
        [OORoadshow oo_modelWithJson:roadshowDict];
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        block();
    });
}
- (void)timer2{
    void (^block)()=^{
        NSString *str=@"Oprah takes a huge gamble on weight loss giant Amazon slaps some of its users with lawsuit New Orleans ranks No. 1 on the list for jobs in this field 7 things to try out before deciding to retire from work Cuban shares the advice that made him a success";

        int location=arc4random()%str.length-1;
        location=location<0?0:location;
        int length=arc4random()%(11)+1;
        if (location+length>str.length) {
            length=(int)str.length-location;
        }
        NSString *name=[str substringWithRange:NSMakeRange(location, length)];
        NSString *age=[NSString stringWithFormat:@"%d",arc4random()%52+18];
        NSString *uid=[NSString stringWithFormat:@"%d",arc4random()%2+1];
        NSString *sex=[NSString stringWithFormat:@"%d",arc4random()%2];

        NSDictionary *userDict= @{@"id":uid,@"name":name,@"sex":sex,@"age":age,@"location":@"aaaa"};
        [OOUser oo_modelWithJson:userDict];
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        block();
    });
}

#pragma mark --
#pragma mark -- tableView delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.roadshows.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DemoTableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"DemoTableViewCell"];
    cell.roadshow=self.roadshows[indexPath.row];
    return cell;
}

#pragma mark --
#pragma mark -- getter


- (UITableView*)tableView{
    if (!_tableView) {
        CGRect frame=self.view.bounds;
        frame.origin.y=20;
        frame.size.height-=20;
        _tableView=[[UITableView alloc]initWithFrame:frame style:UITableViewStylePlain];
        _tableView.delegate=self;
        _tableView.dataSource=self;
        _tableView.rowHeight=100;
        [_tableView registerNib:[UINib nibWithNibName:@"DemoTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"DemoTableViewCell"];
    }
    return _tableView;
}

- (NSMutableArray*)roadshows{
    if (!_roadshows) {
        _roadshows=[NSMutableArray array];
    }
    return _roadshows;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
