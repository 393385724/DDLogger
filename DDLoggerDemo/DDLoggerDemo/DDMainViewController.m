//
//  DDMainViewController.m
//  DDLoggerDemo
//
//  Created by lilingang on 16/2/29.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import "DDMainViewController.h"
#import <DDLogger/DDLogger.h>

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
    if ([[DDLogger sharedInstance] isShowLogView]) {
        sender.titleLabel.text = @"log显示页面";
        [[DDLogger sharedInstance] hidenLogView];
    } else {
        sender.titleLabel.text = @"关闭log显示页面";
        [[DDLogger sharedInstance] showLogView];
    }
}
- (IBAction)viewLocalLogAction:(id)sender {
    [[DDLogger sharedInstance] pikerLogWithViewController:self eventHandler:^(NSArray *logList) {
        NSLog(@"%@",logList);
        [logList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[NSFileManager defaultManager] removeItemAtPath:obj error:nil];
        }];
    }];
}

- (IBAction)writeLogAction:(id)sender {
    DDLog(@"%@",self.textView.text);
}
@end
