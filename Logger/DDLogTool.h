//
//  DDLogTool.h
//  FitRunning
//
//  Created by lilingang on 15/9/18.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDLogTool : NSObject

/**
 *  @brief  是否需要重定向输出
 *
 *  @return 模拟器以及debug 返回NO，其余情况返回YES
 */
+ (BOOL)shouldRedirect;

/**
 *  @brief  根据指定的format返回相应的时间字符串
 *
 *  @param format 日期格式
 *
 *  @return 根据format转换的时间字符串
 */
+ (NSString *)getDateTimeStringWithFormat:(NSString *)format;


/**
 *  @brief 格式化输出日志
 *
 *  @param message  日志内容
 *
 *  @return 格式化后的日志内容
 */
+ (NSString *)formatLogMessage:(NSString *)message;

/**
 *  @brief 格式话crash输出日志
 *
 *  @param exception  NSException 对象
 *
 *  @return 格式化后的日志内容
 */
+ (NSString *)formatExceptionHandler:(NSException *)exception;
@end
