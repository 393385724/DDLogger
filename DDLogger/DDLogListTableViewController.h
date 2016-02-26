//
//  DDLogListTableViewController.h
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDLogListTableViewController;

@protocol DDLogListTableViewControllerDelegate <NSObject>
@required
/**
 *  @brief 有选择的数据源的时候回调
 *
 *  @param viewController DDLogListTableViewController
 *  @param logList        当前选中的log日志
 */
- (void)logListTableViewController:(DDLogListTableViewController *)viewController didSelectedLog:(NSArray *)logList;
/**
 *  @brief 取消操作
 */
- (void)logListTableViewControllerDidCancel;
@end

@interface DDLogListTableViewController : UITableViewController

/**
 *  @brief 回调代理
 */
@property (nonatomic, weak) id <DDLogListTableViewControllerDelegate> delegate;

/**
 *  @brief 数据源
 */
@property (nonatomic, copy) NSArray *dataSoure;

/**
 *  @brief 日志的缓存目录
 */
@property (nonatomic, copy) NSString *logDirectory;

@end
