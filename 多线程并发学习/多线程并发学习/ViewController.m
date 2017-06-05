//
//  ViewController.m
//  多线程并发学习
//
//  Created by qwkj on 2017/6/5.
//  Copyright © 2017年 qwkj. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

      NSLog(@"%s",__func__);
//    [self asyncDoSomethingWithThreadMaxNum:6];
//    [self groupDemo];
    [self groupDemo2];
//    [self dispatch_semaphoreDemo];
    
      NSLog(@"%s",__func__);
}

//测试能一次开启多少子线程
-(void)testMaxNumThread{
    NSLog(@"方法开始");
    //    dispatch_semaphore_t semaphore = dispatch_semaphore_create(5);
    int max =100;
    for (int i=0; i<max; i++) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //注意：GCD中开多少条线程是由系统根据CUP繁忙程度决定的，如果任务很多，GCD会开启适当的子线程，并不会让所有任务同时执行
            //这里使用iphone6s,同时有最多60多个线程开启。
            sleep(1);
            NSLog(@"%d,线程：%@",i,[NSThread currentThread]);
        });
    }
    NSLog(@"方法结束");
}

//使用信号量控制dispatch_semaphore以及dispatch_group_t，对多个请求进行最大请求限制，并且所有请求结束统一返回

-(void)asyncDoSomethingWithThreadMaxNum:(int )maxNum{
        NSLog(@"方法头部");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_group_t aGroup = dispatch_group_create();
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(maxNum);
        for (int i = 0; i<50; i++) {
            //等待信号量时会导致for循环停止，阻塞当前线程，所以信号量的等待在这里不能放主线程
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_group_async(aGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                sleep(2);
                NSLog(@"%d,线程：%@",i,[NSThread currentThread]);
                dispatch_semaphore_signal(semaphore);
            });
        }
        dispatch_group_notify(aGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"所有都执行完了");
        });

    });
    
    NSLog(@"方法末尾");
}
//使用dispatch_semaphore来对30个请求进行信号量控制，最多就只能执行5个异步请求
-(void)dispatch_semaphoreDemo{
    NSLog(@"方法头部");
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(5);
    int max =50;
    for (int i=0; i<max; i++) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

            sleep(2);
            NSLog(@"%d,线程：%@",i,[NSThread currentThread]);
            dispatch_semaphore_signal(semaphore);
            //这里可以尝试将信号量控制代码去掉，会发现他们的打印几乎是同一个时刻打印，加上信号量后会俺最大信号量数，这里是5，一组一组的打印log
        });
    }
    NSLog(@"方法末尾");
}
-(void)groupDemo2{
    //这种方式和下面的方式其实差不多，只是现在类似于信号量一样了，每次一个用dispatch_group_enter(group);代表一个线程进去了线程组，你必须至少等待一个线程结束。然后依次这样，enter，leave一一对应，到最后一个线程leave时就可以通知结束了。demo中你可以尝试注释掉一个leave，当enter数量比leave多时dispatch_group_notify就不会被调用，因为它一直在等待它对应的leave，却不知道等待的只是一个梦。当leave比enter多时，那就悲剧了。dispatch_group_notify会被调用，因为所有的enter已经找到属于它的leave了，但是多出来的最后一个leave调用时，由于没有enter配对，导致她觉得自己一个弱女子被欺骗了，然后就不知所措，奔溃了...
    NSLog(@"开始");
    //1.创建队列组
    dispatch_group_t group = dispatch_group_create();
    //2.创建队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //3.多次使用队列组的方法执行任务, 只有异步方法
    //3.1.执行3次循环
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        for (NSInteger i = 0; i < 3; i++) {
            NSLog(@"group-01 - %@", [NSThread currentThread]);
        }
        dispatch_group_leave(group);
    });
    
    //3.2.主队列执行8次循环
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        for (NSInteger i = 0; i < 8; i++) {
            NSLog(@"group-02 - %@", [NSThread currentThread]);
        }
        dispatch_group_leave(group);
    });
    
    //3.3.执行5次循环
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        sleep(3);
        for (NSInteger i = 0; i < 5; i++) {
            NSLog(@"group-03 - %@", [NSThread currentThread]);
        }
        dispatch_group_leave(group);
        dispatch_group_leave(group);
    });
    
    //4.都完成后会自动通知
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"完成 - %@", [NSThread currentThread]);
    });
        NSLog(@"方法末尾");
}
//使用group同步多个u异步线程，然后统一回调
-(void)groupDemo{
    NSLog(@"开始");
    //1.创建队列组
    dispatch_group_t group = dispatch_group_create();
    //2.创建队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //3.多次使用队列组的方法执行任务, 只有异步方法
    //3.1.执行3次循环
    dispatch_group_async(group, queue, ^{
        for (NSInteger i = 0; i < 3; i++) {
            NSLog(@"group-01 - %@", [NSThread currentThread]);
        }
    });
    
    //3.2.主队列执行8次循环
    dispatch_group_async(group, dispatch_get_main_queue(), ^{
        for (NSInteger i = 0; i < 8; i++) {
            NSLog(@"group-02 - %@", [NSThread currentThread]);
        }
    });
    
    //3.3.执行5次循环
    dispatch_group_async(group, queue, ^{
        sleep(3);
        for (NSInteger i = 0; i < 5; i++) {
            NSLog(@"group-03 - %@", [NSThread currentThread]);
        }
    });
    
    //4.都完成后会自动通知
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"完成 - %@", [NSThread currentThread]);
    });
    NSLog(@"方法末尾");

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
