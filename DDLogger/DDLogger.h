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
 模式               标 识           DEBUG                     RELEASE
 1、NSLog            无       打印到控制台                      无输出
 2、DDLog            无       打印到控制台/输出到文件            输出到文件
 3、DDLogInfo      [INFO]     打印到控制台/输出到文件            输出到文件
 4、DDLogWarn      [WARN]     打印到控制台/输出到文件            输出到文件
 5、DDLogError     [ERROR]    打印到控制台/输出到文件            输出到文件
 */

#ifdef DEBUG

#define NSLog(...)                NSLog(__VA_ARGS__);

#else

#define NSLog(...)                {};

#endif

#define DDLog(...)                DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelNone,__VA_ARGS__);
#define DDLogInfo(...)            DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelInfo,__VA_ARGS__);
#define DDLogWarn(...)            DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelWarn,__VA_ARGS__);
#define DDLogError(...)           DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelError,__VA_ARGS__);

#endif /* DDLogger_h */
