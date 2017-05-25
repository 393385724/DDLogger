//
//  HMLogConsoleView.h
//  HMLogger
//
//  Created by lilingang on 16/2/17.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HMLogConsoleView : UIView

@property (nonatomic, assign) BOOL isShow;

/**
 *  @brief 展示consoleView
 */
- (void)show;

/**
 *  @brief 移除consoleView
 *
 *  @param complete 结束回调
 */
- (void)dismiss:(void(^)())complete;

/**
 *  @brief 追加输出
 *
 *  @param logString 内容
 */
- (void)appendLog:(NSString *)logString;

@end
