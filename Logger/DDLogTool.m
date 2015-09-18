//
//  DDLogTool.m
//  FitRunning
//
//  Created by lilingang on 15/9/18.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import "DDLogTool.h"
#import <pthread.h>

@implementation DDLogTool

+ (BOOL)shouldRedirect{
    if(isatty(STDOUT_FILENO)) {
        return NO;
    }
    UIDevice *device = [UIDevice currentDevice];
    if([[device model] hasSuffix:@"Simulator"]){
        return NO;
    }
    return YES;
}

+ (NSString *)getDateTimeStringWithFormat:(NSString *)format{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[NSLocale currentLocale ].localeIdentifier]];
    [formatter setDateFormat:format];
    return [formatter stringFromDate:[NSDate date]];
}


+ (NSString *)formatLogMessage:(NSString *)message{
    NSProcessInfo* info = [NSProcessInfo processInfo];
    __uint64_t threadId;
    if (pthread_threadid_np(0, &threadId)) {
        threadId = pthread_mach_thread_np(pthread_self());
    }
    NSString *dateStr = [self getDateTimeStringWithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
    NSString *logString = [NSString stringWithFormat:@"%@ %@[%d,%llu] %@\n", dateStr, info.processName, info.processIdentifier, threadId, message];
    return logString;
}

+ (NSString *)formatExceptionHandler:(NSException *)exception{
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSArray *symbols = [exception callStackSymbols];
    NSMutableString *strSymbols = [[ NSMutableString alloc ] init ];
    for (NSString *item in symbols){
        [strSymbols appendString: item];
        [strSymbols appendString: @"\r\n"];
    }
    NSString *dateStr = [self getDateTimeStringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *crashString = [NSString stringWithFormat:@"<- %@ ->[ Uncaught Exception ]\r\nName: %@, Reason: %@\r\n[ Fe Symbols Start ]\r\n%@[ Fe Symbols End ]\r\n\r\n", dateStr, name, reason, strSymbols];
    return crashString;
}

@end
