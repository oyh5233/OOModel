//
//  ViewController.m
//  OOModel
//

#import "ViewController.h"
#import "OOUser.h"
#import "OORoadshow.h"
static void * key1=&key1;
static void * key2=&key2;
@interface ViewController ()
@property (nonatomic, strong)NSMutableDictionary * dictionary;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [OOModel openDatabaseWithFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"db.sqlite"]];
    dispatch_queue_set_specific(dispatch_get_main_queue(), key1, (__bridge void *)self, NULL);
    dispatch_queue_set_specific(dispatch_get_main_queue(), key2, (__bridge void *)self, NULL);

    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timer) userInfo:nil repeats:YES];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)timer{
    void (^block)()=^{
        NSString *age=[NSString stringWithFormat:@"%d",arc4random()%17+1];
        NSString *uid=[NSString stringWithFormat:@"%d",arc4random()%19+1];
        NSString *rid=[NSString stringWithFormat:@"%d",arc4random()%9999+1];
        NSString *membercount=[NSString stringWithFormat:@"%d",arc4random()%299+1];
        NSDictionary *userDict= @{@"id":uid,@"name":@"名字",@"sex":@"1",@"age":age};
        NSDictionary *roadshowDict=@{@"id":rid,@"membercount":membercount,@"title":@"标题",@"creator":userDict};
        OORoadshow *roadshow=[OORoadshow oo_modelWithJsonDictionary:roadshowDict];
        [self.dictionary setObject:roadshow forKey:@(roadshow.rid)];
    };
//    if (arc4random()%2==0) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                block();
//            });
//        });
//    }else{
        block();
//    }
  
}
#pragma mark --
#pragma mark -- getter

- (NSMutableDictionary*)dictionary{
    if (!_dictionary) {
        _dictionary=[NSMutableDictionary dictionary];
    }
    return _dictionary;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
