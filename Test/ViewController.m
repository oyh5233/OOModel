//
//  ViewController.m
//  OOModel
//

#import "ViewController.h"
#import "OORoadshow.h"
#import "DemoTableViewCell.h"
#import "WMUser.h"
#import <sys/time.h>
#import "sqlite3.h"
typedef void (^RoadshowBlock) ();
typedef void (^UserBlock) ();

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray * roadshows;
@property (nonatomic, strong) UITableView    *tableView;
@property (nonatomic, strong) RoadshowBlock  roadshowBlock;
@property (nonatomic, strong) UserBlock      userBlock;
@property (nonatomic, assign) sqlite3        *db;
@property (nonatomic, assign) sqlite3_stmt   *stmt1;
@property (nonatomic, assign) sqlite3_stmt   *stmt2;

@end
#define LOG_ERROR(_code_) _log_error(_code_,self.db,__LINE__)
static inline void _log_error(int code,sqlite3 *db,int line){
//    const char * msg=sqlite3_errmsg(db);
//    if (strcmp(msg, "not an error")||strcmp(msg, "unknown error")) {
//        return;
//    }
    printf("\n%d] %d",line,code);
}
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);
//    LOG_ERROR(sqlite3_open([[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"db.sqlite"] cStringUsingEncoding:NSUTF8StringEncoding], &_db));
//    sqlite3_stmt *stmt=NULL;
//    LOG_ERROR(sqlite3_prepare_v2(self.db, "CREATE TABLE IF NOT EXISTS 't1' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'idx' INTERGER NOT NULL,'ts' REAL)", -1, &stmt, 0));
//    LOG_ERROR(sqlite3_step(stmt));
//    LOG_ERROR(sqlite3_finalize(stmt));
//    LOG_ERROR(sqlite3_prepare_v2(self.db, "CREATE TABLE IF NOT EXISTS 't2' ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'idx' INTERGER NOT NULL,'ts' REAL)", -1, &stmt, 0));
//    LOG_ERROR(sqlite3_step(stmt));
//    LOG_ERROR(sqlite3_finalize(stmt));
//    int c= 1000;
//    int s= 2000;
//    LOG_ERROR(sqlite3_prepare_v2(self.db, "insert into t1(idx,ts) values (?,?)", -1, &_stmt1, 0));
//    LOG_ERROR(sqlite3_prepare_v2(self.db, "insert into t2(idx,ts) values (?,?)", -1, &_stmt2, 0));
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        for (int i =s;i<s+c;i++){
//            LOG_ERROR(sqlite3_reset(self.stmt1));
//            LOG_ERROR(sqlite3_bind_int(self.stmt1, 1, i));
//            LOG_ERROR(sqlite3_bind_double(self.stmt1, 2, (double)i));
//            LOG_ERROR(sqlite3_step(self.stmt1));
//        }
//        LOG_ERROR(sqlite3_finalize(self.stmt1));
//    });
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        for (int i =s;i<s+c;i++){
//            LOG_ERROR(sqlite3_reset(self.stmt2));
//            LOG_ERROR(sqlite3_bind_int(self.stmt2, 1, i));
//            LOG_ERROR(sqlite3_bind_double(self.stmt2, 2, (double)i));
//            LOG_ERROR(sqlite3_step(self.stmt2));
//        }
//        LOG_ERROR(sqlite3_finalize(self.stmt1));
//    });
//    sqlite3_close_v2(self.db);
//    [NSObject oo_setGlobalDB:[OODatabase dbWithFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"db.sqlite"]]];
    [self test1];
//    [self test2];
    
  
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)test1{
    [WMUser oo_setDb:[[OODb alloc]initWithFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"db.sqlite"]]];
    NSMutableArray *jsons=[NSMutableArray array];
    int count1=1;
    int count2=10000;
    for (int i=0;i<count1;i++){
        NSMutableDictionary * json=[[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"user" ofType:@"json"]] options:NSJSONReadingAllowFragments error:nil] mutableCopy];
        [json setObject:@(count1+i) forKey:@"user_id"];
        [jsons addObject:[json copy]];
    }
    NSArray *users=[WMUser oo_modelsWithJsonDictionaries:jsons];
    [jsons removeAllObjects];
    for (int i=0;i<count2;i++){
        NSMutableDictionary * json=[[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"user" ofType:@"json"]] options:NSJSONReadingAllowFragments error:nil] mutableCopy];
        [json setObject:@(count2+i) forKey:@"user_id"];
        [jsons addObject:[json copy]];
    }
    YYBenchmark(^{
        NSArray *users=[WMUser oo_modelsWithJsonDictionaries:jsons];
//        [users enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        }];
    }, ^(double ms) {
        NSLog(@"%.2f",ms);
    });
}

- (void)test2{
//    for (int i = 0; i < 3 ; i++){
//        NSDictionary *jsonDictionary=@{
//                                       @"id":[NSString stringWithFormat:@"%d",i+1],
//                                       @"extra":@{
//                                               @"creator":@{
//                                                       @"id":i<2?[NSString stringWithFormat:@"%d",1]:[NSString stringWithFormat:@"%d",2]
//                                                       }
//                                               }
//                                       };
//        
//        OORoadshow *roadshow=[OORoadshow oo_modelWithJson:jsonDictionary];
//        [self.roadshows addObject:roadshow];
//    }
//    [self.view addSubview:self.tableView];
//    NSTimer *timer1=[NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(timer1) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop]addTimer:timer1 forMode:NSRunLoopCommonModes];
//    [timer1 fire];
//    NSTimer *timer11=[NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(timer1) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop]addTimer:timer11 forMode:NSRunLoopCommonModes];
//    [timer11 fire];
//    NSTimer *timer2=[NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(timer2) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop]addTimer:timer2 forMode:NSRunLoopCommonModes];
//    [timer2 fire];
//    NSTimer *timer22=[NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(timer2) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop]addTimer:timer22 forMode:NSRunLoopCommonModes];
//    [timer22 fire];
}
- (void)timer1{
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.roadshowBlock();
        self.userBlock();
        self.userBlock();
    });
}

- (void)timer2{
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.roadshowBlock();
        self.userBlock();
        self.userBlock();
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

- (RoadshowBlock)roadshowBlock{
    if (!_roadshowBlock) {
//        _roadshowBlock=^{
//            NSString *str=@"Oprah takes a huge gamble on weight loss giant Amazon slaps some of its users with lawsuit New Orleans ranks No. 1 on the list for jobs in this field 7 things to try out before deciding to retire from work Cuban shares the advice that made him a success";
//            int location=arc4random()%str.length-1;
//            location=location<0?0:location;
//            int length=arc4random()%((str.length-location-1))+1;
//            NSString *title=[str substringWithRange:NSMakeRange(location, length)];
//            
//            
//            NSString *rid=[NSString stringWithFormat:@"%d",arc4random()%3+1];
//            NSString *membercount=[NSString stringWithFormat:@"%d",arc4random()%98+1];
//            NSDictionary *roadshowDict=@{@"id":rid,@"membercount":membercount,@"title":title};
//            [OORoadshow oo_modelWithJson:roadshowDict];
//        };
    }
    return _roadshowBlock;
}

- (UserBlock)userBlock{
    if(!_userBlock){
//        _userBlock=^{
//            NSString *str=@"Oprah takes a huge gamble on weight loss giant Amazon slaps some of its users with lawsuit New Orleans ranks No. 1 on the list for jobs in this field 7 things to try out before deciding to retire from work Cuban shares the advice that made him a success";
//            
//            int location=arc4random()%str.length-1;
//            location=location<0?0:location;
//            int length=arc4random()%(11)+1;
//            if (location+length>str.length) {
//                length=(int)str.length-location;
//            }
//            NSString *name=[str substringWithRange:NSMakeRange(location, length)];
//            NSString *age=[NSString stringWithFormat:@"%d",arc4random()%52+18];
//            NSString *uid=[NSString stringWithFormat:@"%d",arc4random()%2+1];
//            NSString *sex=[NSString stringWithFormat:@"%d",arc4random()%2];
//            
//            NSDictionary *userDict= @{@"id":uid,@"name":name,@"sex":sex,@"age":age,@"location":@"aaaa"};
//            [OOUser oo_modelWithJson:userDict];
//        };
    }
    return _userBlock;
}

static inline void YYBenchmark(void (^block)(void), void (^complete)(double ms)) {
    // <QuartzCore/QuartzCore.h> version
    /*
     extern double CACurrentMediaTime (void);
     double begin, end, ms;
     begin = CACurrentMediaTime();
     block();
     end = CACurrentMediaTime();
     ms = (end - begin) * 1000.0;
     complete(ms);
     */
    
    // <sys/time.h> version
    struct timeval t0, t1;
    gettimeofday(&t0, NULL);
    block();
    gettimeofday(&t1, NULL);
    double ms = (double)(t1.tv_sec - t0.tv_sec) * 1e3 + (double)(t1.tv_usec - t0.tv_usec) * 1e-3;
    complete(ms);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
