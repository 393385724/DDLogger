//
//  HMEncryptLogger.h
//  HMLoggerDemo
//
//  Created by 李林刚 on 2017/5/24.
//  Copyright © 2017年 LiLingang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMLoggerDefine.h"

@interface HMEncryptLogger : NSObject

+ (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix;

+ (void)setLogSuffix:(NSString *)logSuffix maxDays:(NSUInteger)maxDays;

+ (void)writeLogFile:(const char *)file
            function:(const char *)function
                line:(int)line
               level:(HMLogLevel)level
                 tag:(NSString *)tag
              format:(NSString *)format
                args:(va_list)args;

+ (void)flushToDiskSync:(BOOL)isSync;

+ (void)stopLog;

@end
