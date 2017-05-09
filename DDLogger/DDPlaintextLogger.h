//
//  DDLoggerClient.h
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString * const DDPlaintextLogPathExtension;

@interface DDPlaintextLogger : NSObject

/**
 *  @brief 指定log文件存储的路径
 *
 *  @param cacheDirectory log存储的目录
 *  @param nameprefix 日志文件前缀
 */
- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory nameprefix:(NSString *)nameprefix;

/**
 打印log

 @param log log信息
 */
- (void)printfLog:(NSString *)log;

/**
 *  @brief 将内存中的log存入磁盘
 *
 *  @param isSync YES ? 同步 : 异步
 */
- (void)flushToDiskSync:(BOOL)isSync;


/**
 *  @brief 停止log收集
 */
- (void)stopLog;

@end
