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

#ifdef __IPHONE_8_0
@interface DDLogListTableViewController ()<DDLogListTableViewCellDelegate,DDLogDetailViewControllerDelegate>
#else
@interface DDLogListTableViewController ()<DDLogListTableViewCellDelegate,DDLogDetailViewControllerDelegate,UIAlertViewDelegate>
#endif

@end

@implementation DDLogListTableViewController{
    NSMutableSet *_selectedLogSet;
    NSString *_deleteFileName;
    NSString *_deleteFilePath;
    NSIndexPath *_deleteIndexPath;
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
    BOOL isSelected = [_selectedLogSet containsObject:name.stringByDeletingPathExtension];
    if ([name.pathExtension hasPrefix:@"hms"]) {
        name = [name.stringByDeletingPathExtension stringByAppendingString:@"㊙️"];
    }
    [cell updateWithTitle:name.stringByDeletingPathExtension isSelected:isSelected];
}

#pragma mark -  Private Methods

- (void)deleteFile {
    [[NSFileManager defaultManager] removeItemAtPath:_deleteFilePath error:nil];
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[_deleteIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
    NSMutableArray *mutDataSource = [self.dataSoure mutableCopy];
    [mutDataSource removeObjectAtIndex:_deleteIndexPath.row];
    self.dataSoure = [mutDataSource copy];
    [self.tableView endUpdates];
    [_selectedLogSet removeObject:_deleteFileName];
    self.title = [NSString stringWithFormat:@"日志列表(%lu)",(unsigned long)[self.dataSoure count]];
    self.navigationItem.rightBarButtonItem.enabled = [_selectedLogSet count] > 0 ? YES : NO;
    [self cancleDelele];
}

- (void)cancleDelele {
    _deleteFileName = nil;
    _deleteFilePath = nil;
    _deleteIndexPath = nil;
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        _deleteFileName = self.dataSoure[indexPath.row];
        _deleteFilePath = [self.dataSource logListTableViewController:self logFilePathWithFileName:_deleteFileName];
        _deleteIndexPath = indexPath;
        NSString *title = @"⚠️";
        NSString *message = [NSString stringWithFormat:@"确定删除文件(%@)?",_deleteFileName];
#ifdef __IPHONE_8_0
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self deleteFile];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self cancleDelele];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:deleteAction];
        [self presentViewController:alertController animated:YES completion:nil];
#else
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alertView show];
#endif
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *fileName = self.dataSoure[indexPath.row];
    if ([fileName.pathExtension hasPrefix:@"hms"]) {
        return;
    } else {
        DDLogDetailViewController *viewController = [[DDLogDetailViewController alloc] init];
        viewController.delegate = self;
        viewController.currentIndexPath = indexPath;
        viewController.hasPiker = [_selectedLogSet containsObject:fileName];
        viewController.disPlayName = [fileName stringByDeletingPathExtension];
        viewController.logFilePath = [self.dataSource logListTableViewController:self logFilePathWithFileName:fileName];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark - UIAlertViewDelegate

#ifndef __IPHONE_8_0
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self cancleDelele];
    } else {
        [self deleteFile];
    }
}
#endif

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
