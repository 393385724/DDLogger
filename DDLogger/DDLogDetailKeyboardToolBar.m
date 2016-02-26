//
//  DDLogDetailKeyboardToolBar.m
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import "DDLogDetailKeyboardToolBar.h"

@interface DDLogDetailKeyboardToolBar ()


@end

@implementation DDLogDetailKeyboardToolBar

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.barStyle = UIBarStyleBlack;
        self.translucent = YES;
        
        UIBarButtonItem *previousBarItem = [[UIBarButtonItem alloc] initWithTitle:@"上一项"
                                                                            style:UIBarButtonItemStyleBordered
                                                                           target:self
                                                                           action:@selector(previousField)];
        
        UIBarButtonItem *nextBarItem = [[UIBarButtonItem alloc] initWithTitle:@"下一项"
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(nextField)];
        
        UIBarButtonItem *spaceBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                      target:nil
                                                                                      action:nil];
        UIBarButtonItem *doneBarItem = [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                                                        style:UIBarButtonItemStyleDone
                                                                       target:self
                                                                       action:@selector(registerKeyboard)];
        
        [self setItems:[NSArray arrayWithObjects:previousBarItem, nextBarItem, spaceBarItem,doneBarItem, nil]];
    }
    return self;
}

#pragma mark - Private Method

- (void)previousField{
    if (self.toolBarDelegate && [self.toolBarDelegate respondsToSelector:@selector(keyboardToolBarPrevious)]) {
        [self.toolBarDelegate keyboardToolBarPrevious];
    }
}

- (void)nextField{
    if (self.toolBarDelegate && [self.toolBarDelegate respondsToSelector:@selector(keyboardToolBarNext)]) {
        [self.toolBarDelegate keyboardToolBarNext];
    }
}

- (void)registerKeyboard{
    if (self.toolBarDelegate && [self.toolBarDelegate respondsToSelector:@selector(keyboardToolBarDone)]) {
        [self.toolBarDelegate keyboardToolBarDone];
    }
}

@end
