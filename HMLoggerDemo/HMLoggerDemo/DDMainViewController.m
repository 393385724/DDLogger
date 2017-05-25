//
//  DDMainViewController.m
//  HMLoggerDemo
//
//  Created by lilingang on 16/2/29.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import "DDMainViewController.h"
#import "HMLogger.h"

@interface DDMainViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation DDMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:tap];
}

- (void)tap:(UITapGestureRecognizer *)tap{
    [self.textView resignFirstResponder];
}

- (IBAction)showLogViewAction:(UIButton *)sender {
    if ([[HMLogger Logger] isConsoleShow]) {
        sender.titleLabel.text = @"log显示页面";
        [[HMLogger Logger] hidenConsole];
    } else {
        sender.titleLabel.text = @"关闭log显示页面";
        [[HMLogger Logger] showConsole];
    }
}
- (IBAction)viewLocalLogAction:(id)sender {
    [[HMLogger Logger] pikerLogWithViewController:self eventHandler:^(NSArray *logPathList) {
        [logPathList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[NSFileManager defaultManager] removeItemAtPath:obj error:nil];
        }];
    }];
}

- (IBAction)writeLogAction:(id)sender {
    NSLog(@"NSLog 这是一条测试数据你能看到么这是一条测试数据你能看到么");
    HMLogWarn(@"HMLogWarn 这是一条测试数据你能看到么这是一条测试数据你能看到么");
    HMLogError(@"HMLogError 这是一条测试数据你能看到么这是一条测试数据你能看到么");
    HMLogInfo(@"HMLogFatal 这是一条测试数据你能看到么这是一条测试数据你能看到么");
}

//- (void)badAccess
//{
//    void (*nullFunction)() = NULL;
//    
//    nullFunction();
//}
@end
