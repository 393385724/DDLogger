//
//  DDEncryptLogger.m
//  DDLoggerDemo
//
//  Created by 李林刚 on 2017/5/24.
//  Copyright © 2017年 LiLingang. All rights reserved.
//

#import "DDEncryptLogger.h"

#import <mars/xlog/xlogger.h>
#import <mars/xlog/appender.h>
#import <sys/xattr.h>

@implementation DDEncryptLogger

+ (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix {
    // set do not backup for logpath
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    setxattr([cacheDirectory UTF8String], attrName, &attrValue, sizeof(attrValue), 0, 0);
    
    // init xlogger
#if DEBUG
    xlogger_SetLevel(kLevelAll);
    appender_set_console_log(true);
#else
    xlogger_SetLevel(kLevelInfo);
    appender_set_console_log(false);
#endif
    if (nameprefix) {
        appender_open(kAppednerAsync, [cacheDirectory UTF8String], nameprefix.UTF8String);
    } else {
        appender_open(kAppednerAsync, [cacheDirectory UTF8String], "");
    }
}

+ (void)setLogSuffix:(NSString *)logSuffix maxDays:(NSUInteger)maxDays {
    if (logSuffix) {
        appender_set_logSuffix(logSuffix.UTF8String);
    }
    if (maxDays > 0) {
        appender_set_maxLogAliveTime(maxDays * 24 * 60 * 60);
    }
}

+ (void)writeLogFile:(const char *)file
            function:(const char *)function
                line:(int)line
               level:(HMLogLevel)level
                 tag:(NSString *)tag
              format:(NSString *)format
                args:(va_list)args{
    NSString *body = [[NSString alloc] initWithFormat:format arguments:args];
    TLogLevel tLevel = kLevelInfo;
    switch (level) {
        case HMLogLevelDebug:
            tLevel = kLevelDebug;
            break;
        case HMLogLevelInfo:
            tLevel = kLevelInfo;
            break;
        case HMLogLevelWarn:
            tLevel = kLevelWarn;
            break;
        case HMLogLevelError:
            tLevel = kLevelError;
            break;
        case HMLogLevelFatal:
            tLevel = kLevelFatal;
            break;
        default:
            break;
    }
    if (tag) {
        xlogger2(tLevel, tag.UTF8String, file, function, line, "%s",body.UTF8String);
    } else {
        xlogger2(tLevel, XLOGGER_TAG, file, function, line, "%s",body.UTF8String);
    }
}

+ (void)flushToDiskSync:(BOOL)isSync{
    if (isSync) {
        appender_flush_sync();
    } else {
        appender_flush();
    }
}

+ (void)stopLog {
    appender_close();
}

@end
