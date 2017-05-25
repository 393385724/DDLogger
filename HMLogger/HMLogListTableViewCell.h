//
//  HMLogListTableViewCell.h
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HMLogListTableViewCell;

@protocol HMLogListTableViewCellDelegate <NSObject>

@required

- (void)tableViewCell:(HMLogListTableViewCell *)cell buttonDidSelected:(BOOL)isSelected;

@end

@interface HMLogListTableViewCell : UITableViewCell

@property (nonatomic, weak) id<HMLogListTableViewCellDelegate> delegate;

- (void)updateWithTitle:(NSString *)title isSelected:(BOOL)isSelected;

@end
