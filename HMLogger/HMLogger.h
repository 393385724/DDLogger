//
//  HMLogger.h
//  HMLoggerDemo
//
//  Created by 李林刚 on 2017/5/6.
//  Copyright © 2017年 LiLingang. All rights reserved.
//
/**
 每次启动时会删除过期文件，只保留十天内的日志文件
 */

#import <Foundation/Foundation.h>
#import "HMLoggerDefine.h"

@class UIViewController;

/**
 如下定义了log输出宏，对Debug和release分别作了特殊处理,你也可以自定义宏
 模式              标 识           DEBUG                     RELEASE
 1、NSLog          [D]       打印到控制台/输出到文件             无输出
 2、HMLogInfo      [I]       打印到控制台/输出到文件            输出到文件
 3、HMLogWarn      [W]       打印到控制台/输出到文件            输出到文件
 4、HMLogError     [E]       打印到控制台/输出到文件            输出到文件
 */

#ifdef NSLog
#undef NSLog
#endif

#ifdef DDLogInfo
#undef DDLogInfo
#endif

#ifdef DDLogWarn
#undef DDLogWarn
#endif

#ifdef DDLogError
#undef DDLogError
#endif

#ifndef NSLog
#define NSLog(...)                [[HMLogger Logger] writeLogFile:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ level:HMLogLevelDebug tag:nil format:__VA_ARGS__];
#endif


#ifndef DDLogInfo
#define DDLogInfo(...)            [[HMLogger Logger] writeLogFile:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ level:HMLogLevelInfo tag:nil format:__VA_ARGS__];
#endif


#ifndef DDLogWarn
#define DDLogWarn(...)            [[HMLogger Logger] writeLogFile:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ level:HMLogLevelWarn tag:nil format:__VA_ARGS__];
#endif


#ifndef DDLogError
#define DDLogError(...)           [[HMLogger Logger] writeLogFile:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ level:HMLogLevelError tag:nil format:__VA_ARGS__];
#endif

/**
 *  @brief 选取log日志回调结果
 *
 *  @param logPathList      选中的log日志路径数组
 */
typedef void(^HMLoggerPikerEventHandler) (NSArray *logPathList);

@interface HMLogger : NSObject

/**
 日志存储路径
 */
@property (readonly) NSString *logDirectory;

/**
 唯一初始化方法

 @return HMLogger
 */
+ (HMLogger *)Logger;

/**
 开启log日志，在程序刚启动的时候调用=

 @param cacheDirectory 日志缓存路径
 @param nameprefix 单个日志文件名前缀
 @param logPathExtension 日志后缀
 @param maxDays 保留最长时间（加密则是时间，不加密则是文件个数）
 @param encrypt 是否加密
 */
- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix
                  logPathExtension:(NSString *)logPathExtension
                           maxDays:(NSUInteger)maxDays
                           encrypt:(BOOL)encrypt;

/**
 开启log日志，在程序刚启动的时候调用
 
 @param cacheDirectory 日志缓存路径
 @param nameprefix 单个日志文件名前缀
 @param encrypt 是否加密
 */
- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix
                           encrypt:(BOOL)encrypt;

/**
 写一条日志到日志系统

 @param file 调用该函数的文件名
 @param function 调用改函数的函数名
 @param line 当前行数
 @param level HMLogLevel
 @param tag 功能
 @param format 多参数字符串
 */
- (void)writeLogFile:(const char *)file
            function:(const char *)function
                line:(int)line
               level:(HMLogLevel)level
                 tag:(NSString *)tag
              format:(NSString *)format, ...;


/**
 内存中的日志存入文件

 @param sync 是否同步
 */
- (void)flushToDiskSync:(BOOL)sync;

/*******自定义手机控制台输出*********/
/**
 *  @brief 当前是否显示LoggerConsole
 *
 *  @return YES ？已经显示 ：未显示
 */
- (BOOL)isConsoleShow;

/**
 *  @brief 显示Console
 */
- (void)showConsole;

/**
 *  @brief 隐藏Console
 */
- (void)hidenConsole;


/*******本地log拾取器*********/

/**
 计算本地log日志大小

 @param completionBlock 回调 大小单位 bytes
 */
- (void)calculateSizeWithCompletionBlock:(void(^)(NSUInteger fileCount, NSUInteger totalSize))completionBlock;


/**
 获取本地log文件名

 @return NSArray
 */
- (NSArray *)getLogFileNames;

/**
 *  @brief 查看本地存在的log日志
 *
 *  @param viewController 当前的Viewontroller
 *  @param handler        选取回调结果
 */
- (void)pikerLogWithViewController:(UIViewController *)viewController
                      eventHandler:(HMLoggerPikerEventHandler)handler;



- (instancetype)initWithCoder:(NSCoder *)aDecoder UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
@end
