//
//  DDLogListTableViewController.m
//  MDLoginSDK
//
//  Created by lilingang on 16/2/26.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import "DDLogListTableViewController.h"
#import "DDLogDetailViewController.h"
#import "DDLogListTableViewCell.h"

NSString *const DDCellReuseIdentifier = @"DDLogListTableViewCellReuseIdentifier";

@interface DDLogListTableViewController ()<DDLogListTableViewCellDelegate,DDLogDetailViewControllerDelegate>

@end

@implementation DDLogListTableViewController{
    NSMutableSet *_selectedLogSet;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"日志列表(%lu)",(unsigned long)[self.dataSoure count]];
    
    //leftBarButtonItem
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonAction)];
    
    //rightBarButtonItem
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonAction)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DDLogListTableViewCell" bundle:nil] forCellReuseIdentifier:DDCellReuseIdentifier];
    self.tableView.rowHeight = 50;
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    _selectedLogSet = [[NSMutableSet alloc] init];
}

#pragma mark - Action

- (void)leftButtonAction{
    if (self.delegate && [self.delegate respondsToSelector:@selector(logListTableViewControllerDidCancel)]) {
        [self.delegate logListTableViewControllerDidCancel];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rightButtonAction{
    if (self.delegate && [self.delegate respondsToSelector:@selector(logListTableViewController:didSelectedLog:)]) {
        NSMutableArray *selectedLogFilePaths = [NSMutableArray arrayWithCapacity:[_selectedLogSet count]];
        for (NSString *fileName in [_selectedLogSet allObjects]) {
            NSString *filePath = [self.dataSource logListTableViewController:self logFilePathWithFileName:fileName];
            [selectedLogFilePaths addObject:filePath];
        }
        [self.delegate logListTableViewController:self didSelectedLog:selectedLogFilePaths];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateCell:(DDLogListTableViewCell *)cell indexPath:(NSIndexPath *)indexPath{
    NSString *name = self.dataSoure[indexPath.row];
    NSString *disPlayName = [name stringByReplacingOccurrencesOfString:@".log" withString:@""];
    BOOL isSelected = [_selectedLogSet containsObject:name];
    [cell updateWithTitle:disPlayName isSelected:isSelected];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSoure count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DDLogListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DDCellReuseIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    [self updateCell:cell indexPath:indexPath];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *fileName = self.dataSoure[indexPath.row];
    DDLogDetailViewController *viewController = [[DDLogDetailViewController alloc] init];
    viewController.delegate = self;
    viewController.currentIndexPath = indexPath;
    viewController.hasPiker = [_selectedLogSet containsObject:fileName];
    viewController.disPlayName = [fileName stringByDeletingPathExtension];
    viewController.logFilePath = [self.dataSource logListTableViewController:self logFilePathWithFileName:fileName];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - DDLogListTableViewCellDelegate

- (void)tableViewCell:(DDLogListTableViewCell *)cell buttonDidSelected:(BOOL)isSelected{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSString *name = self.dataSoure[indexPath.row];
    BOOL hasContentName = [_selectedLogSet containsObject:name];
    hasContentName ? [_selectedLogSet removeObject:name] : [_selectedLogSet addObject:name];
    self.navigationItem.rightBarButtonItem.enabled = [_selectedLogSet count] > 0 ? YES : NO;
}

#pragma mark - DDLogDetailViewControllerDelegate

- (void)logDetailViewControllerDidSelectedWithIndexPath:(NSIndexPath *)indexPath{
    NSString *name = self.dataSoure[indexPath.row];
    DDLogListTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    BOOL hasContentName = [_selectedLogSet containsObject:name];
    hasContentName ? [_selectedLogSet removeObject:name] : [_selectedLogSet addObject:name];
    [self updateCell:cell indexPath:indexPath];
    self.navigationItem.rightBarButtonItem.enabled = [_selectedLogSet count] > 0 ? YES : NO;
}

@end
