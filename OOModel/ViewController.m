//
//  ViewController.m
//  OOModel
//

#import "ViewController.h"
#import "OOUser.h"
@interface ViewController ()
@property (nonatomic, strong)NSMutableDictionary * dictionary;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [OOModel openDatabaseWithFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"db.sqlite"]];
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timer) userInfo:nil repeats:YES];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)timer{
    void (^block)()=^{
        NSString *age=[NSString stringWithFormat:@"%d",arc4random()%3+1];
        NSString *uid=[NSString stringWithFormat:@"%d",arc4random()%3+1];
        OOUser *user=[OOUser oo_modelWithJsonDictionary:@{@"id":uid,@"name":@"名字",@"sex":@"1",@"age":age}];
        [self.dictionary setObject:user forKey:@(user.uid)];
    };
    if (arc4random()%2==0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block();
        });
    }else{
        block();
    }
  
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
