//
//  DDLogConsoleView.m
//  DDLogger
//
//  Created by lilingang on 16/2/17.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import "DDLogConsoleView.h"

@interface DDLogConsoleView ()

@property (nonatomic, strong) UIButton *closeResponseButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) UITapGestureRecognizer *logViewUserInteractionEnabledTap;

@end

@implementation DDLogConsoleView

- (instancetype)init{
    CGRect frame = CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 300);
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        self.userInteractionEnabled = NO;
        
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
        self.textView.font = [UIFont fontWithName:@"Courier" size:12];
        self.textView.backgroundColor = self.backgroundColor;
        self.textView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        self.textView.textColor = [UIColor greenColor];
        self.textView.editable = NO;
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame) - 60, 20)];
        [button setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
        [button setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:12];
        [button setTitle:@"Close rolling function" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(closeResponseButtonAction) forControlEvents:UIControlEventTouchUpInside];
        button.hidden = YES;
        self.closeResponseButton = button;
        
        button = nil;
        button = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame) - 60, 0, 60, 20)];
        [button setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:12];
        [button setTitle:@"Clear Log" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(clearlogButtonAction) forControlEvents:UIControlEventTouchUpInside];
        button.hidden = YES;
        self.clearButton = button;
        
        [self addSubview:self.textView];
        [self addSubview:self.closeResponseButton];
        [self addSubview:self.clearButton];
        
        [self appendLog:@"Console: Copyright © 2016 Lilingang Design\n A finger click console five consecutive times to open rolling function\n--------------------------------------\n"];
    }
    return self;
}

#pragma mark - Public

- (void)show{
    [[self mainWindow] addSubview:self];
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = CGRectMake(CGRectGetMinX(self.frame), 300, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    } completion:^(BOOL finished) {
        [[self mainWindow] addGestureRecognizer:self.logViewUserInteractionEnabledTap];
    }];
}

- (void)dismiss:(void(^)())complete{
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [[self mainWindow] removeGestureRecognizer:self.logViewUserInteractionEnabledTap];
        if (complete) {
            complete();
        }
    }];
}

- (void)appendLog:(NSString *)logString{
    if ([NSThread currentThread] == [NSThread mainThread]){
        [self setConsoleText:logString];
    } else {
        [self performSelectorOnMainThread:@selector(setConsoleText:)
                               withObject:logString
                            waitUntilDone:NO];
    }
}


#pragma mark - Private Methods

- (void)setConsoleText:(NSString *)text{
    self.textView.text = [NSString stringWithFormat:@"%@\n%@", self.textView.text,text];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length, 0)];
    });
}

- (void)clearlogButtonAction{
    self.textView.text = @"";
}

- (void)logViewUserInteractionEnabledTapAction{
    self.userInteractionEnabled = YES;
    self.closeResponseButton.hidden = NO;
    self.clearButton.hidden = NO;
}

- (void)closeResponseButtonAction{
    self.userInteractionEnabled = NO;
    self.closeResponseButton.hidden = YES;
    self.clearButton.hidden = YES;
}

- (UITapGestureRecognizer *)logViewUserInteractionEnabledTap{
    if (nil == _logViewUserInteractionEnabledTap) {
        _logViewUserInteractionEnabledTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(logViewUserInteractionEnabledTapAction)];
        _logViewUserInteractionEnabledTap.numberOfTapsRequired = 5;
        _logViewUserInteractionEnabledTap.numberOfTouchesRequired = 1;
    }
    return _logViewUserInteractionEnabledTap;
}

- (UIWindow *)mainWindow{
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate respondsToSelector:@selector(window)]){
        return [application.delegate window];
    } else {
        return [application keyWindow];
    }
}

@end
