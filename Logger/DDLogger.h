//
//  DDLogger.h
//  FitRunning
//
//  Created by lilingang on 15/9/17.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLogTypeDef.h"

#define NSLog(args...)  ExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);

void ExtendNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);

@interface DDLogger : NSObject

/**
 *  @brief log保存在本地的最长时间 单位/s 默认1周
 */
@property (nonatomic, assign) NSInteger maxLogAge;

/**
 *  @brief log在本地保存最大的空间，单位/bit 默认没有限制
 */
@property (nonatomic, assign) NSUInteger maxLogSize;


+ (DDLogger *)sharedInstance;

/**
 *  @brief  开始收集log 在- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions中调用

 */
- (void)startLog;

/**
 *  @brief 停止收集log
 */
- (void)stopLog;

/**
 *  @brief  log存在额目录
 *
 *  @return /Documents/DDLog
 */
- (NSString *)logDirectory;

/**
 *  @brief  根据已存在的log名字返回相对路径
 *
 *  @param fileName 已存在的log
 *
 *  @return NSString
 */
- (NSString *)logFilePathWithFileName:(NSString *)fileName;

/**
 *  @brief  获取本地所有的log列表
 *
 *  @return NSArray
 */
- (NSArray *)getLogList;

/**
 *  @brief  计算本地log的大小
 *
 *  @param completionBlock 回调
 */
- (void)calculateSizeWithCompletionBlock:(DDLogCalculateSizeBlock)completionBlock;

/**
 *  @brief 清除本地log缓存
 *
 *  @param UsePolicy       是否使用策略，YES 根据设定的age size 选择性删除 NO 全部删除
 *  @param completionBlock 完成回调
 */
- (void)cleanDiskUsePolicy:(BOOL)UsePolicy completionBlock:(DDLogNoParamsBlock)completionBlock;


@end
