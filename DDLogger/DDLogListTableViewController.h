//
//  DDLogListTableViewController.h
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DDLogListTableViewControllerDataSoure;
@protocol DDLogListTableViewControllerDelegate;


@interface DDLogListTableViewController : UITableViewController

/**
 *  @brief 回调代理
 */
@property (nonatomic, weak) id <DDLogListTableViewControllerDelegate> delegate;
@property (nonatomic, weak) id <DDLogListTableViewControllerDataSoure> dataSource;

/**
 *  @brief 数据源
 */
@property (nonatomic, copy) NSArray *dataSoure;

@end


@protocol DDLogListTableViewControllerDataSoure <NSObject>

@required
- (NSString *)logListTableViewController:(DDLogListTableViewController *)viewController logFilePathWithFileName:(NSString *)fileName;

@end

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