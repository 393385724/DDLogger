//
//  DDLogListTableViewCell.h
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDLogListTableViewCell;

@protocol DDLogListTableViewCellDelegate <NSObject>

@required

- (void)tableViewCell:(DDLogListTableViewCell *)cell buttonDidSelected:(BOOL)isSelected;

@end

@interface DDLogListTableViewCell : UITableViewCell

@property (nonatomic, weak) id<DDLogListTableViewCellDelegate> delegate;

- (void)updateWithTitle:(NSString *)title isSelected:(BOOL)isSelected;

@end
