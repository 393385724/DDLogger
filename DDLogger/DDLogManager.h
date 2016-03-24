//
//  DDLogManager.h
//  DDLogger
//
//  Created by lilingang on 15/9/18.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  @brief log是按照自然天来存储的
 */
@interface DDLogManager : NSObject

/**
 *  @brief 设置log缓存的绝对目录,默认Library/Caches/DDLog
 */
@property (nonatomic, copy) NSString *cacheDirectory;

/**
 *  @brief log保存在本地的最长时间 单位/s 默认30Day
 */
@property (nonatomic, assign) NSInteger maxLogAge;

/**
 *  @brief log在本地保存最大的空间，单位/bytes 默认100M
 */
@property (nonatomic, assign) NSUInteger maxLogSize;

/**
 *  @brief 当前使用的log日志文件路径
 */
@property (nonatomic, copy, readonly) NSString *currentUseLogFilePath;

/**
 *  @brief 判断当前使用的文件路径是否存在
 *
 *  @return YES ？存在 ：不存在
 */
- (BOOL)isCurrentFilePathExit;

/**
 *  @brief 根据文件名获取log日志的完整路径
 *
 *  @param fileName log文件名
 *
 *  @return NSString 文件路径
 */
- (NSString *)filePathWithName:(NSString *)fileName;

/**
 *  @brief 获取本地缓存中所有的log文件名
 *
 *  @param error 错误信息接收
 *
 *  @return NSArray
 */
- (NSArray *)getLogFileNames:(NSError **)error;

/**
 *  @brief 计算所有log日志的大小
 *
 *  @param completionBlock 回调 大小单位 bytes
 */
- (void)calculateSizeWithCompletionBlock:(void(^)(NSUInteger fileCount, NSUInteger totalSize))completionBlock;

/**
 *  @brief 清除本地log
 *
 *  @param usePolicy       YES ？按照预设的策略清理 ： 全部移除
 *  @param completionBlock 回调
 */
- (void)cleanDiskUsePolicy:(BOOL)usePolicy completionBlock:(void(^)())completionBlock;

@end
