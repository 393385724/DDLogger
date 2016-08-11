//
//  DDLoggerClient.h
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#import <Foundation/Foundation.h>

@class UIViewController;

/**@brief 打印的log类型*/
typedef NS_ENUM(NSUInteger, DDLogLevel) {
    /**不区分类型*/
    DDLogLevelNone       = 0,
    /**正常信息的log*/
    DDLogLevelInfo       = 1,
    /**警告类型的log*/
    DDLogLevelWarn       = 2,
    /**Error类型的Log*/
    DDLogLevelError      = 3,
};

/**
 *  @brief 选取log日志回调结果
 *
 *  @param logList      选中的log日志路径数组
 */
typedef void(^DDLoggerPikerEventHandler) (NSArray *logPathList);

/**
 *  @brief 自定义LOG
 *
 *  @param file         宏 __FILE__
 *  @param lineNumber   宏 __LINE__
 *  @param functionName 宏 __PRETTY_FUNCTION__
 *  @param logLevel     DDLogLevel
 *  @param format       自定义参数
 */
void DDExtendNSLog(const char *file, int lineNumber, const char *functionName, DDLogLevel logLevel, NSString *format, ...);

@interface DDLoggerClient : NSObject

/**
 *  @brief 唯一初始化方法
 *
 *  @return DDLoggerClient对象
 */
+ (DDLoggerClient *)sharedInstance;

/**
 *  @brief 指定log文件存储的路径
 *
 *  @param cacheDirectory log存储的目录，nil则使用默认目录Library/Caches/DDLogger
 *  @param fileName       log文件名，nil则根据日期动态生成文件名 eg.2016-08-08
 */
- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                          fileName:(NSString *)fileName;

/**
 *  @brief 配置内存允许存储的最大log
 *
 *  @param maxLine 最大条数.DDExtendNSLog执行一次算一条
 *  @param maxSize 占用的最大内存，估算存储空间
 */
- (void)configMemoryMaxLine:(NSInteger)maxLine
                    maxSize:(float)maxSize;

/**
 *  @brief 停止log收集
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
 *  @brief 查看本地存在的log日志
 *
 *  @param viewController 当前的Viewontroller
 *  @param handler        选取回调结果
 */
- (void)pikerLogWithViewController:(UIViewController *)viewController
                      eventHandler:(DDLoggerPikerEventHandler)handler;
@end
