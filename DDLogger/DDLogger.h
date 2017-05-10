//
//  DDLogger.h
//  DDLoggerDemo
//
//  Created by 李林刚 on 2017/5/6.
//  Copyright © 2017年 LiLingang. All rights reserved.
//
/**
 每次启动时会删除过期文件，只保留十天内的日志文件
 */

#import <Foundation/Foundation.h>

@class UIViewController;

/**
 log打印的信息
 
 - DDLogLevelDebug:  调试信息
 - DDLogLevelInfo:   信息
 - DDLogLevelWarn:   警告
 - DDLogLevelError:  基本错误
 - DDLogLevelFatal:  致命错误
 */
typedef NS_ENUM(NSUInteger, DDLogLevel) {
    DDLogLevelDebug         = 0,
    DDLogLevelInfo          = 1,
    DDLogLevelWarn          = 2,
    DDLogLevelError         = 3,
    DDLogLevelFatal         = 4,
};

/**
 如下定义了log输出宏，对Debug和release分别作了特殊处理,你也可以自定义宏
 模式              标 识           DEBUG                     RELEASE
 1、NSLog          [D]       打印到控制台/输出到文件             无输出
 2、DDLogInfo      [I]       打印到控制台/输出到文件            输出到文件
 3、DDLogWarn      [W]       打印到控制台/输出到文件            输出到文件
 4、DDLogError     [E]       打印到控制台/输出到文件            输出到文件
 5、DDLogFatal     [F]       打印到控制台/输出到文件            输出到文件
 */

#define NSLog(...)                [[DDLogger Logger] writeLogFile:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ level:DDLogLevelDebug tag:nil format:__VA_ARGS__];
#define DDLogInfo(...)            [[DDLogger Logger] writeLogFile:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ level:DDLogLevelInfo tag:nil format:__VA_ARGS__];
#define DDLogWarn(...)            [[DDLogger Logger] writeLogFile:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ level:DDLogLevelWarn tag:nil format:__VA_ARGS__];
#define DDLogError(...)           [[DDLogger Logger] writeLogFile:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ level:DDLogLevelError tag:nil format:__VA_ARGS__];
#define DDLogFatal(...)           [[DDLogger Logger] writeLogFile:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ level:DDLogLevelFatal tag:nil format:__VA_ARGS__];

/**
 *  @brief 选取log日志回调结果
 *
 *  @param logList      选中的log日志路径数组
 */
typedef void(^DDLoggerPikerEventHandler) (NSArray *logPathList);

@interface DDLogger : NSObject

/**
 日志存储路径
 */
@property (readonly) NSString *logDirectory;

/**
 唯一初始化方法

 @return DDLogger
 */
+ (DDLogger *)Logger;

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
 @param level DDLogLevel
 @param tag 功能
 @param format 多参数字符串
 */
- (void)writeLogFile:(const char *)file
            function:(const char *)function
                line:(int)line
               level:(DDLogLevel)level
                 tag:(NSString *)tag
              format:(NSString *)format, ...;

/**
 关闭日志，在程序退出的时候调用
 */
- (void)stopLog;


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
                      eventHandler:(DDLoggerPikerEventHandler)handler;



- (instancetype)initWithCoder:(NSCoder *)aDecoder UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
@end
