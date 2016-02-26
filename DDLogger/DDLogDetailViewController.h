//
//  DDLogDetailViewController.h
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DDLogDetailViewControllerDelegate <NSObject>
@required
- (void)logDetailViewControllerDidSelectedWithIndexPath:(NSIndexPath *)indexPath;
@end

@interface DDLogDetailViewController : UIViewController

@property (nonatomic, weak) id<DDLogDetailViewControllerDelegate> delegate;

/**
 *  @brief 当前选中的cell在tableView的位置
 */
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

/**
 *  @brief 是否已经选中上传
 */
@property (nonatomic, assign) BOOL hasPiker;

/**
 *  @brief 显示的名字
 */
@property (nonatomic, copy) NSString *disPlayName;

/**
 *  @brief 文件路径
 */
@property (nonatomic, copy) NSString *logFilePath;

@end
