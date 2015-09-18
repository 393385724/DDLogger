//
//  DDLogManger.h
//  FitRunning
//
//  Created by lilingang on 15/9/18.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLogTypeDef.h"


@interface DDLogManger : NSObject

@property (nonatomic, copy, readonly) NSString *cacheDirectory;

/**
 *  @brief log保存在本地的最长时间 单位/s 默认1周
 */
@property (nonatomic, assign) NSInteger maxLogAge;

/**
 *  @brief log在本地保存最大的空间，单位/bit 默认没有限制
 */
@property (nonatomic, assign) NSUInteger maxLogSize;

- (NSString *)logFilePath;

- (NSArray *)getLogList;

- (void)calculateSizeWithCompletionBlock:(DDLogCalculateSizeBlock)completionBlock;

- (void)cleanDiskUsePolicy:(BOOL)usePolicy completionBlock:(DDLogNoParamsBlock)completionBlock;

@end
