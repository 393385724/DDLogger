//
//  DDMainViewController.m
//  DDLoggerDemo
//
//  Created by lilingang on 16/2/29.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import "DDMainViewController.h"
#import "DDLogger.h"

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
    if ([[DDLogger Logger] isConsoleShow]) {
        sender.titleLabel.text = @"log显示页面";
        [[DDLogger Logger] hidenConsole];
    } else {
        sender.titleLabel.text = @"关闭log显示页面";
        [[DDLogger Logger] showConsole];
    }
}
- (IBAction)viewLocalLogAction:(id)sender {
    [[DDLogger Logger] pikerLogWithViewController:self eventHandler:^(NSArray *logPathList) {
        [logPathList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[NSFileManager defaultManager] removeItemAtPath:obj error:nil];
        }];
    }];
}

- (IBAction)writeLogAction:(id)sender {
    NSLog(@"NSLog 这是一条测试数据你能看到么这是一条测试数据你能看到么");
    DDLogWarn(@"DDLogWarn 这是一条测试数据你能看到么这是一条测试数据你能看到么");
    DDLogError(@"DDLogError 这是一条测试数据你能看到么这是一条测试数据你能看到么");
    DDLogInfo(@"DDLogFatal 这是一条测试数据你能看到么这是一条测试数据你能看到么");
}

//- (void)badAccess
//{
//    void (*nullFunction)() = NULL;
//    
//    nullFunction();
//}
@end
