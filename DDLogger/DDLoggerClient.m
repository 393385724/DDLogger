//
//  DDLoggerClient.m
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#import "DDLoggerClient.h"
#import <pthread.h>
#import "DDLoggerManager.h"
#import "DDLogConsoleView.h"
#import "DDLogListTableViewController.h"

@interface DDLoggerClient ()<DDLogListTableViewControllerDelegate, DDLogListTableViewControllerDataSoure>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) DDLogConsoleView *consoleView;

@property (nonatomic, copy) DDLoggerPikerEventHandler eventHandler;

@end

@implementation DDLoggerClient{
    BOOL _forceRedirect;
}

+ (DDLoggerClient *)sharedInstance{
    static DDLoggerClient*_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DDLoggerClient alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[NSLocale currentLocale ].localeIdentifier]];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return self;
}

- (void)setupForceRedirect:(BOOL)forceRedirect{
    _forceRedirect = forceRedirect;
}

#pragma mark - Public Methods
- (BOOL)isConsoleShow{
    return self.consoleView != nil;
}

- (void)showConsole{
    if (![self isConsoleShow]) {
        self.consoleView = [[DDLogConsoleView alloc] init];
        [self.consoleView show];
    }
}

- (void)hidenConsole{
    if ([self isConsoleShow]) {
        [self.consoleView dismiss:^{
            self.consoleView = nil;
        }];
    }
}

- (void)pikerLogWithViewController:(UIViewController *)viewController
                      eventHandler:(DDLoggerPikerEventHandler)handler{
    if (!handler) {
        return;
    }
    self.eventHandler = handler;
    DDLogListTableViewController *logListViewController = [[DDLogListTableViewController alloc] initWithStyle:UITableViewStylePlain];
    logListViewController.delegate = self;
    logListViewController.dataSource = self;
    logListViewController.dataSoure = [[DDLoggerManager sharedInstance] getLogFileNames];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:logListViewController];
    [navigationController.navigationBar setTranslucent:NO];
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - DDLogListTableViewControllerDataSoure

- (NSString *)logListTableViewController:(DDLogListTableViewController *)viewController logFilePathWithFileName:(NSString *)fileName{
    return [[DDLoggerManager sharedInstance] filePathWithName:fileName];
}

#pragma mark - DDLogListTableViewControllerDelegate

- (void)logListTableViewController:(DDLogListTableViewController *)viewController didSelectedLog:(NSArray *)logList{
    self.eventHandler(logList);
    self.eventHandler = nil;
}

- (void)logListTableViewControllerDidCancel{
    self.eventHandler(nil);
    self.eventHandler = nil;
}


#pragma mark - Private Methods

/**
 *  @brief  是否需要重定向输出到文件(release模式)
 *
 *  @return YES ? 重定向输出 : 不做任何操作
 */
- (BOOL)shouldRedirect{
    if (_forceRedirect) {
        return YES;
    } else {
#if (TARGET_IPHONE_SIMULATOR || DEBUG)
        return NO;
#else
        return YES;
#endif
    }
}

FILE *fp = NULL;
- (void)printfLog:(NSString *)log{
    const char *filePath = [[DDLoggerManager sharedInstance].currentLogFilePath cStringUsingEncoding:NSASCIIStringEncoding];
    if ([self shouldRedirect]) {
        int exist = access(filePath,W_OK);
        if ((fp = fopen(filePath, "a+")) == NULL) {
            fprintf(stdout, "%s","file open failed");
        }
        if (exist != 0 && fp != NULL) {
            freopen(filePath, "a+", stdout);
        }
    }
    if ([self isConsoleShow]) {
        [self.consoleView appendLog:log];
    }
    fprintf(stdout,"%s",[log UTF8String]);
    if (fp != NULL) {
        fflush(stdout);
        fclose(fp);
    }
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
    
    NSString *dateStr = [self.dateFormatter stringFromDate:[NSDate date]];
    NSString *logString = [NSString stringWithFormat:@"%@ %@[%d,%llu] %@\n", dateStr, info.processName, info.processIdentifier, threadId, message];
    return logString;
}

@end

void DDExtendNSLog(const char *file, int lineNumber, const char *functionName,DDLogLevel logLevel, NSString *format, ...) {
    va_list ap;
    va_start (ap, format);
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    NSString *fileString = [NSString stringWithUTF8String:file];
    NSString *fileName = [fileString lastPathComponent];
    NSString *logMessage;
    if (functionName != NULL) {
        logMessage = [NSString stringWithFormat:@"<%@ : %d Line %s> %@",fileName,lineNumber,functionName,body];
    } else {
        logMessage = [NSString stringWithFormat:@"<%@ : %d Line> %@",fileName,lineNumber,body];
    }
    switch (logLevel) {
        case DDLogLevelNone:
            break;
        case DDLogLevelError:
            logMessage = [@"ERROR: " stringByAppendingString:logMessage];
            break;
        case DDLogLevelWarning:
            logMessage = [@"WARNING: " stringByAppendingString:logMessage];
            break;
        case DDLogLevelInfo:
            logMessage = [@"INFO: " stringByAppendingString:logMessage];
            break;
        case DDLogLevelDebug: {
            logMessage = [@"DEBUG: " stringByAppendingString:logMessage];
            break;
        default:
            break;
        }
    }
    NSString *formatLogString = [[DDLoggerClient sharedInstance] formatLogMessage:logMessage];
    [[DDLoggerClient sharedInstance] printfLog:formatLogString];
}

void UncaughtExceptionHandler(NSException* exception){
    NSString *name = [exception name];
    NSString *reason = [exception reason];
    NSArray *symbols = [exception callStackSymbols];
    NSMutableString *strSymbols = [[ NSMutableString alloc ] init ];
    for (NSString *item in symbols){
        [strSymbols appendString: item];
        [strSymbols appendString: @"\r\n"];
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[NSLocale currentLocale ].localeIdentifier]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *crashString = [NSString stringWithFormat:@"<- %@ ->[ Uncaught Exception ]\r\nName: %@, Reason: %@\r\n[ Fe Symbols Start ]\r\n%@[ Fe Symbols End ]\r\n\r\n", dateStr, name, reason, strSymbols];
    [[DDLoggerClient sharedInstance] printfLog:crashString];
}