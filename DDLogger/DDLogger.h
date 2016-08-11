//
//  DDLogger.h
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#ifndef DDLogger_h
#define DDLogger_h
#import "DDLoggerClient.h"
#import "DDLoggerManager.h"

/**
 如下定义了log输出宏，对Debug和release分别作了特殊处理,你也可以自定义宏
 模式               标 识        DEBUG                  RELEASE
 1、NSLog            无       打印到控制台                无输出
 2、DDLog            无       打印到控制台               输出到文件
 3、DDLogInfo      [INFO]     打印到控制台               输出到文件
 4、DDLogWarn      [WARN]     打印到控制台               输出到文件
 5、DDLogError     [ERROR]    打印到控制台               输出到文件
 */

#ifdef DEBUG

#define NSLog(...)                NSLog(__VA_ARGS__);
#define DDLog(...)                NSLog(__VA_ARGS__);
#define DDLogInfo(...)            NSLog(__VA_ARGS__);
#define DDLogWarn(...)            NSLog(__VA_ARGS__);
#define DDLogError(...)           NSLog(__VA_ARGS__);

#else

#define NSLog(...)                {};
#define DDLog(...)                DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelNone,[NSString stringWithFormat:__VA_ARGS__]);
#define DDLogInfo(...)            DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelInfo,[NSString stringWithFormat:__VA_ARGS__]);
#define DDLogWarn(...)         DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelWarn,[NSString stringWithFormat:__VA_ARGS__]);
#define DDLogError(...)           DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelError,[NSString stringWithFormat:__VA_ARGS__]);

#endif

#endif /* DDLogger_h */
