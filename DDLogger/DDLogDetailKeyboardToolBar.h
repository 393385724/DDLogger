//
//  DDLogDetailKeyboardToolBar.h
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDLogDetailKeyboardToolBar;

@protocol DDLogDetailKeyboardToolBarDelegate <NSObject>

@optional

- (void)keyboardToolBarPrevious;
- (void)keyboardToolBarNext;
- (void)keyboardToolBarDone;

@end

@interface DDLogDetailKeyboardToolBar : UIToolbar

@property (nonatomic, weak) id<DDLogDetailKeyboardToolBarDelegate> toolBarDelegate;

@end
