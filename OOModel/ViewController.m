//
//  ViewController.m
//  OOModel
//

#import "ViewController.h"
#import "OOUser.h"
@interface ViewController ()

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
        NSString *age=[NSString stringWithFormat:@"%d",arc4random()%99+1];
        NSString *uid=[NSString stringWithFormat:@"%d",arc4random()%99+1];
        OOUser *user=[OOUser modelWithJsonDictionary:@{@"id":uid,@"name":@"名字",@"sex":@"1",@"age":age}];
        [user update];
    };
    if (arc4random()%2==0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block();
        });
    }else{
        block();
    }
  
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
