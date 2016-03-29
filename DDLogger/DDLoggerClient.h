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
    /**Error类型的Log*/
    DDLogLevelError      = 1,
    /**警告类型的log*/
    DDLogLevelWarning    = 2,
    /**正常信息的log*/
    DDLogLevelInfo       = 3,
    /**调试使用的log*/
    DDLogLevelDebug      = 4
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
 *  @brief 设置是否强制重定向日志到文件,默认只有release环境才会写入文件
 *
 *  @param forceRedirect YES？强制写文件
 */
- (void)setupForceRedirect:(BOOL)forceRedirect;

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
