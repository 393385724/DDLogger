//
//  DDLogDetailViewController.m
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import "DDLogDetailViewController.h"
#import <ICTextView/ICTextView.h>
#import "DDLogDetailKeyboardToolBar.h"

@interface DDLogDetailViewController ()<UISearchBarDelegate,DDLogDetailKeyboardToolBarDelegate>

@property (weak, nonatomic) IBOutlet ICTextView *myTextView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (nonatomic, strong) DDLogDetailKeyboardToolBar *toolBar;

@end

@implementation DDLogDetailViewController{
    BOOL _hasEdit;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:self.logFilePath error:nil];
    unsigned long long fileSize = [attributesDictionary fileSize];
    if (fileSize < 1024*1024) {
        self.title = [self.disPlayName stringByAppendingFormat:@"[%.2f KB]",fileSize/1024.0];
    } else {
        self.title = [self.disPlayName stringByAppendingFormat:@"[%.2f MB]",fileSize/1024.0/1024.0];
    }
    
    //leftBarButtonItem
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonAction)];
    
    //rightBarButtonItem
    [self updateRightBarButtonItem];
    
    //搜索操作工具条
    self.toolBar = [[DDLogDetailKeyboardToolBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
    self.toolBar.toolBarDelegate = self;
    [self.searchBar setInputAccessoryView:self.toolBar];
    
    
    self.myTextView.circularSearch = YES;
    self.myTextView.scrollPosition = ICTextViewScrollPositionMiddle;
    self.myTextView.searchOptions = NSRegularExpressionCaseInsensitive;

    self.myTextView.text = @"Console: Copyright © 2016 Lilingang Design\n--------------------------------------\n";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrameNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *context = [NSString stringWithContentsOfFile:self.logFilePath encoding:NSUTF8StringEncoding error:nil];
        if ([context length]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.myTextView.text = [self.myTextView.text stringByAppendingString:context];
            });
        }
    });
}

#pragma mark - Private Mehtod

- (void)updateRightBarButtonItem{
    UIImage *image = [UIImage imageNamed:@"ddlog_check_icon_normal"];
    if (self.hasPiker) {
        image = [UIImage imageNamed:@"ddlog_check_icon_selected"];
    }
    UIButton*rightButton = [[UIButton alloc]initWithFrame:CGRectMake(0,0,25,25)];
    [rightButton setImage:image forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(rightButtonAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem= [[UIBarButtonItem alloc]initWithCustomView:rightButton];
}

#pragma mark - Action

- (void)leftButtonAction{
    if (self.delegate && [self.delegate respondsToSelector:@selector(logDetailViewControllerDidSelectedWithIndexPath:)] && _hasEdit) {
        [self.delegate logDetailViewControllerDidSelectedWithIndexPath:self.currentIndexPath];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightButtonAction{
    _hasEdit = !_hasEdit;
    self.hasPiker = !self.hasPiker;
    [self updateRightBarButtonItem];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self keyboardToolBarNext];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self keyboardToolBarNext];
}

#pragma mark - DDLogDetailKeyboardToolBarDelegate

- (void)keyboardToolBarPrevious{
    [self searchMatchInDirection:ICTextViewSearchDirectionBackward];
}

- (void)keyboardToolBarNext{
    [self searchMatchInDirection:ICTextViewSearchDirectionForward];
}

-(void)keyboardToolBarDone{
    [self.searchBar resignFirstResponder];
    [self.myTextView resignFirstResponder];
    self.searchBar.text = @"";
    self.countLabel.text = @"";
    [self.myTextView resetSearch];
}

- (void)searchMatchInDirection:(ICTextViewSearchDirection)direction{
    NSString *searchString = self.searchBar.text;
    if (searchString.length){
        [self.myTextView scrollToString:searchString searchDirection:direction];
    } else {
        [self.myTextView resetSearch];
    }
    NSUInteger numberOfMatches = self.myTextView.numberOfMatches;
    self.countLabel.text = numberOfMatches ? [NSString stringWithFormat:@"%lu/%lu", (unsigned long)self.myTextView.indexOfFoundString + 1, (unsigned long)numberOfMatches] : @"0/0";
}

#pragma mark - Notification

- (void)keyboardWillChangeFrameNotification:(NSNotification *)notification{
    if (!notification) {
        return;
    }
    UIEdgeInsets newInsets = UIEdgeInsetsZero;
    CGRect keyboardEndFrame;
    [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    CGFloat offset = CGRectGetHeight(self.view.bounds) - CGRectGetMinY(keyboardEndFrame) + CGRectGetHeight(self.toolBar.frame);
    newInsets.bottom = newInsets.bottom + offset;
    self.myTextView.contentInset = newInsets;
    self.myTextView.scrollIndicatorInsets = newInsets;
}

@end
