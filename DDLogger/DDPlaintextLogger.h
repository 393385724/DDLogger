//
//  DDLoggerClient.h
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#import <Foundation/Foundation.h>
#import "DDLoggerDefine.h"

@interface DDPlaintextLogger : NSObject

/**
 开启日志，指定log文件存储

 @param cacheDirectory log存储的目录
 @param nameprefix 日志文件前缀
 */
+ (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix;


/**
 配置log文件后缀与保留时间

 @param logSuffix 后缀
 @param fileCount 保留文件数
 */
+ (void)setLogSuffix:(NSString *)logSuffix fileCount:(NSUInteger)fileCount;


/**
 写一行日志到文件

 @param file 文件名
 @param function 函数名
 @param line 所在的行号
 @param level HMLogLevel
 @param tag 功能标签
 @param format 文字格式
 @param args 参数
 */
+ (void)writeLogFile:(const char *)file
            function:(const char *)function
                line:(int)line
               level:(HMLogLevel)level
                 tag:(NSString *)tag
              format:(NSString *)format
                args:(va_list)args;


/**
 将缓存日志存入到文件
 */
+ (void)flushToDisk;

@end
