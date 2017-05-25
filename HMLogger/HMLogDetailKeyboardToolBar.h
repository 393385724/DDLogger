//
//  HMLogDetailKeyboardToolBar.h
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HMLogDetailKeyboardToolBar;

@protocol HMLogDetailKeyboardToolBarDelegate <NSObject>

@optional

- (void)keyboardToolBarPrevious;
- (void)keyboardToolBarNext;
- (void)keyboardToolBarDone;

@end

@interface HMLogDetailKeyboardToolBar : UIToolbar

@property (nonatomic, weak) id<HMLogDetailKeyboardToolBarDelegate> toolBarDelegate;

@end
