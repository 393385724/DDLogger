//
//  HMLogListTableViewController.h
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HMLogListTableViewControllerDataSoure;
@protocol HMLogListTableViewControllerDelegate;


@interface HMLogListTableViewController : UITableViewController

/**
 *  @brief 回调代理
 */
@property (nonatomic, weak) id <HMLogListTableViewControllerDelegate> delegate;
@property (nonatomic, weak) id <HMLogListTableViewControllerDataSoure> dataSource;

/**
 *  @brief 数据源
 */
@property (nonatomic, copy) NSArray *dataSoure;

@end


@protocol HMLogListTableViewControllerDataSoure <NSObject>

@required
- (NSString *)logListTableViewController:(HMLogListTableViewController *)viewController logFilePathWithFileName:(NSString *)fileName;

@end

@protocol HMLogListTableViewControllerDelegate <NSObject>
@required
/**
 *  @brief 有选择的数据源的时候回调
 *
 *  @param viewController HMLogListTableViewController
 *  @param logList        当前选中的log日志
 */
- (void)logListTableViewController:(HMLogListTableViewController *)viewController didSelectedLog:(NSArray *)logList;
/**
 *  @brief 取消操作
 */
- (void)logListTableViewControllerDidCancel;

@end
