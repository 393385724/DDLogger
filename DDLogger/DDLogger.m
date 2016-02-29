//
//  DDLogger.m
//  DDLogger
//
//  Created by lilingang on 15/9/17.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <pthread.h>
#import "DDLogger.h"
#import "DDLogManager.h"
#import "DDLogConsoleView.h"
#import "DDLogListTableViewController.h"


void UncaughtExceptionHandler(NSException* exception);

@interface DDLogger ()<DDLogListTableViewControllerDelegate>

@property (nonatomic, strong) DDLogConsoleView *logView;

@property (nonatomic, strong) DDLogManager *logManger;

@property (nonatomic, strong) NSFileHandle *writeLogFileHandle;


@property (nonatomic, copy) DDPikerLogEventHandler pikerLogEventHandler;

@end

@implementation DDLogger{
    BOOL _hidenLogView;
}

#pragma mark - Life Cycle

+ (DDLogger *)sharedInstance{
    static DDLogger*_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DDLogger alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.logManger = [[DDLogManager alloc] init];
        _hidenLogView = YES;
    }
    return self;
}

#pragma mark - Public Methods

- (void)startLog{
    [self startLogWithMaxLogAge:0 maxLogSize:0 cacheDirectory:nil];
}

- (void)startLogWithMaxLogAge:(NSUInteger)maxLogAge
                   maxLogSize:(NSUInteger)maxLogSize
               cacheDirectory:(NSString *)cacheDirectory{
    if (maxLogAge > 0) {
        self.logManger.maxLogAge = maxLogAge;
    }
    if (maxLogSize > 0) {
        self.logManger.maxLogSize = maxLogSize;
    }
    if (cacheDirectory) {
        self.logManger.cacheDirectory = cacheDirectory;
    }
    
    NSString *logFilePath = [self.logManger currentLogFilePath];
    self.writeLogFileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    [self.writeLogFileHandle seekToEndOfFile];
    if ([self shouldRedirect]) {
        freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
        freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    }
    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
}

- (void)stopLog{
    [self.writeLogFileHandle closeFile];
    self.writeLogFileHandle = nil;
    self.logManger = nil;
}

#pragma mark - Log日志目录接口

- (NSString *)logDirectory{
    return self.logManger.cacheDirectory;
}

- (NSArray *)getLogList:(NSError **)error{
    return [self.logManger getLogList:error];
}

#pragma mark - LogView 查看

- (BOOL)isShowLogView{
    return !_hidenLogView;
}

- (void)showLogView{
    if (_hidenLogView) {
        _hidenLogView = NO;
        self.logView = [[DDLogConsoleView alloc] init];
        [self.logView show];
    }
}

- (void)hidenLogView{
    if (!_hidenLogView) {
        _hidenLogView = YES;
        __weak __typeof(&*self)weakSelf = self;
        [self.logView dismiss:^{
            weakSelf.logView = nil;
        }];
    }
}

#pragma mark - log 拾取器

- (void)pikerLogWithViewController:(UIViewController *)viewController
                      eventHandler:(DDPikerLogEventHandler)handler{
    if (!handler) {
        return;
    }
    self.pikerLogEventHandler = handler;
    DDLogListTableViewController *logListViewController = [[DDLogListTableViewController alloc] initWithStyle:UITableViewStylePlain];
    logListViewController.delegate = self;
    logListViewController.dataSoure = [self.logManger getLogList:nil];
    logListViewController.logDirectory = self.logDirectory;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:logListViewController];
    [navigationController.navigationBar setTranslucent:NO];
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)logWithFile:(NSString *)file lineNumber:(int)lineNumber functionName:(NSString *)functionName body:(NSString *)body{
    NSString *fileName = [file lastPathComponent];
    NSString *logMessage;
    if (functionName) {
        logMessage = [NSString stringWithFormat:@"<%@ : %d Line %@> %@",fileName,lineNumber,functionName,body];
    } else {
        logMessage = [NSString stringWithFormat:@"<%@ : %d Line> %@",fileName,lineNumber,body];
    }
    NSString *logString = [self formatLogMessage:logMessage];
    fprintf(stderr, "%s",[logString UTF8String]);
    [self.logView appendLog:logString];
    [self.writeLogFileHandle writeData:[logString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)uncaughtExceptionHandler:(NSException *)exception{
    NSString *crashString = [self formatExceptionHandler:exception];
    [self.writeLogFileHandle writeData:[crashString dataUsingEncoding:NSUTF8StringEncoding]];
    [self stopLog];
}


/**
 *  @brief  是否需要重定向输出到文件不需要输出到控制台
 *
 *  @return YES ? 重定向输出 : 不做任何操作
 */
- (BOOL)shouldRedirect{
    //若为模拟器则为真,否则为假
#if (TARGET_IPHONE_SIMULATOR || DEBUG)
    return NO;
#else
    //若为终端设备则为真(1)，否则为假(0)
    return isatty(STDOUT_FILENO) == 1;
#endif
}

/**
 *  @brief  根据指定的format返回相应的时间字符串
 *
 *  @param format 日期格式
 *
 *  @return 根据format转换的时间字符串
 */
- (NSString *)getDateTimeStringWithFormat:(NSString *)format{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[NSLocale currentLocale ].localeIdentifier]];
    [formatter setDateFormat:format];
    return [formatter stringFromDate:[NSDate date]];
}

/**
 *  @brief 格式化输出日志
 *
 *  @param message  日志内容
 *
 *  @return 格式化后的日志内容
 */
- (NSString *)formatLogMessage:(NSString *)message{
    NSProcessInfo* info = [NSProcessInfo processInfo];
    __uint64_t threadId;
    if (pthread_threadid_np(0, &threadId)) {
        threadId = pthread_mach_thread_np(pthread_self());
    }
    NSString *dateStr = [self getDateTimeStringWithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
    NSString *logString = [NSString stringWithFormat:@"%@ %@[%d,%llu] %@\n", dateStr, info.processName, info.processIdentifier, threadId, message];
    return logString;
}

/**
 *  @brief 格式化crash输出日志
 *
 *  @param exception  NSException 对象
 *
 *  @return 格式化后的日志内容
 */
- (NSString *)formatExceptionHandler:(NSException *)exception{
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

#pragma mark - DDLogListTableViewControllerDelegate

- (void)logListTableViewController:(DDLogListTableViewController *)viewController didSelectedLog:(NSArray *)logList{
    self.pikerLogEventHandler(self.logDirectory, logList);
    self.pikerLogEventHandler = nil;
}

- (void)logListTableViewControllerDidCancel{
    self.pikerLogEventHandler(self.logDirectory, nil);
    self.pikerLogEventHandler = nil;
}

@end

void DDExtendNSLog(const char *file, int lineNumber, const char *functionName,DDLogLevel logLevel, NSString *format, ...) {
    va_list ap;
    va_start (ap, format);
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    switch (logLevel) {
        case DDLogLevelNone:
            break;
        case DDLogLevelError:
            body = [@"ERRORLEVEL:" stringByAppendingString:body];
            break;
        case DDLogLevelWarning:
            body = [@"WARNINLEVEL:" stringByAppendingString:body];
            break;
        case DDLogLevelInfo:
            body = [@"INFOLEVEL:" stringByAppendingString:body];
            break;
        default:
            break;
    }
    if (functionName == NULL) {
        [[DDLogger sharedInstance] logWithFile:[NSString stringWithUTF8String:file] lineNumber:lineNumber functionName:nil body:body];
    } else {
        [[DDLogger sharedInstance] logWithFile:[NSString stringWithUTF8String:file] lineNumber:lineNumber functionName:[NSString stringWithUTF8String:functionName] body:body];
    }
}

void UncaughtExceptionHandler(NSException* exception){
    [[DDLogger sharedInstance] uncaughtExceptionHandler:exception];
}