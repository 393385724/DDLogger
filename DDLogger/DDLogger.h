//
//  DDLogger.h
//  DDLogger
//
//  Created by lilingang on 15/9/17.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DDLogLevel) {
    DDLogLevelNone = 0,
    DDLogLevelError,
    DDLogLevelWarning,
    DDLogLevelInfo
};

#define DDLog(args...) DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelNone,args);

void DDExtendNSLog(const char *file, int lineNumber, const char *functionName, DDLogLevel logLevel, NSString *format, ...);

@interface DDLogger : NSObject

+ (DDLogger *)sharedInstance;

/**
 *  @brief  开始收集log
 @code
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
        [[DDLogger sharedInstance] startLog];
        return YES;
 }
 @endcode
 */
- (void)startLog;

/**
 *  @brief 开始收集log，并配置默认参数
 *
 *  @param maxLogAge      log保存在本地的最长时间， 单位/s，0代表使用默认值30天
 *  @param maxLogSize     log在本地保存最大的空间，单位/bytes，0代表使用默认值100M
 *  @param cacheDirectory log缓存的绝对目录，nil代表使用默认值Library/Caches/DDLog
 @code
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *cacheDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"HMLOG"];
        [[DDLogger sharedInstance] startLogWithMaxLogAge:60*60*24*7 maxLogSize:1024*1024*5 cacheDirectory:cacheDirectory]; 
        return YES;
 }
 @endcode
 */
- (void)startLogWithMaxLogAge:(NSUInteger)maxLogAge
                   maxLogSize:(NSUInteger)maxLogSize
               cacheDirectory:(NSString *)cacheDirectory;

/**
 *  @brief 停止收集log
 */
- (void)stopLog;

//*************log文件获取***************
/**
 *  @brief  log存在的目录绝对目录
 *
 *  @return NSString
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
 *  @brief 获取本地所有的log列表
 *
 *  @param error 错误捕捉
 *
 *  @return NSArray
 */
- (NSArray *)getLogList:(NSError **)error;


//*************log输出显示查看***************
/**
 *  @brief 当前是否显示logView
 *
 *  @return YES ？已经显示 ：未显示
 */
- (BOOL)isShowLogView;

/**
 *  @brief 显示logView
 */
- (void)showLogView;

/**
 *  @brief 隐藏logView
 */
- (void)hidenLogView;

@end
