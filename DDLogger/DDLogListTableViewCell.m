//
//  DDLogListTableViewCell.m
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import "DDLogListTableViewCell.h"

@interface DDLogListTableViewCell ()

@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation DDLogListTableViewCell

- (void)updateWithTitle:(NSString *)title isSelected:(BOOL)isSelected{
    self.titleLabel.text = title;
    self.selectButton.selected = isSelected;
}

- (IBAction)selectButtonAction:(id)sender {
    self.selectButton.selected = !self.selectButton.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableViewCell:buttonDidSelected:)]) {
        [self.delegate tableViewCell:self buttonDidSelected:self.selectButton.selected];
    }
}

@end
