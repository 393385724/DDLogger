//
//  DDLoggerClient.m
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#import "DDLoggerClient.h"
#import <pthread.h>
#import "DDUncaughtExceptionHandler.h"
#import "DDLoggerManager.h"
#import "DDLogConsoleView.h"
#import "DDLogListTableViewController.h"

NSInteger const DDMaxMessageInMemoryCount = 10;

@interface DDLoggerClient ()<DDLogListTableViewControllerDelegate, DDLogListTableViewControllerDataSoure>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) DDLogConsoleView *consoleView;

@property (nonatomic, copy) DDLoggerPikerEventHandler eventHandler;

//用与缓存处理
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *memoryCaches;

@end

@implementation DDLoggerClient

+ (DDLoggerClient *)sharedInstance{
    static DDLoggerClient*_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DDLoggerClient alloc] init];
    });
    return _sharedInstance;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[NSLocale currentLocale ].localeIdentifier]];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        self.serialQueue = dispatch_queue_create("com.ddlogger.writeQueue", DISPATCH_QUEUE_SERIAL);
        self.memoryCaches = [[NSMutableArray alloc] initWithCapacity:DDMaxMessageInMemoryCount];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminateNotification:) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exceptionHandlerNotification:) name:DDExceptionHandlerNotification object:nil];
    }
    return self;
}

- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                          fileName:(NSString *)fileName{
    [[DDLoggerManager sharedInstance] configCacheDirectory:cacheDirectory fileName:fileName];
    [DDUncaughtExceptionHandler InstallUncaughtExceptionHandler];
}

- (void)stopLog{
    [self flushToDiskSync:NO];
    self.memoryCaches = nil;
    self.serialQueue = nil;
    self.eventHandler = nil;
    self.dateFormatter = nil;
    self.consoleView = nil;
}

#pragma mark - Public Methods
- (BOOL)isConsoleShow{
    return self.consoleView.isShow;
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
 *  @brief 将内存中的log存入磁盘
 *
 *  @param isSync YES ? 同步 : 异步
 */
- (void)flushToDiskSync:(BOOL)isSync{
    if ([self.memoryCaches count] == 0 ||
        !self.memoryCaches) {
        NSLog(@"no more log in memory");
        return;
    }
    NSArray *readyToDiskMessageArray = [self.memoryCaches copy];
    @synchronized (self.memoryCaches) {
        [self.memoryCaches removeAllObjects];
    }
    dispatch_block_t block = ^{
        const char *filePath = [[DDLoggerManager sharedInstance].currentLogFilePath cStringUsingEncoding:NSASCIIStringEncoding];
        FILE *fp = fopen(filePath, "a");
        if (fp) {
            fprintf(fp, "%s", [[readyToDiskMessageArray componentsJoinedByString:@""] UTF8String]);
            fflush(fp);
            fclose(fp);
            fp = NULL;
        }
    };
    if (isSync) {
        dispatch_barrier_sync(self.serialQueue, block);
    } else {
        dispatch_barrier_async(self.serialQueue, block);
    }
}

- (void)printfLog:(NSString *)log{
    if ([self isConsoleShow]) {
        [self.consoleView appendLog:log];
    }
    if (log) {
        [self.memoryCaches addObject:log];
    }
    if ([self.memoryCaches count] >= DDMaxMessageInMemoryCount) {
        [self flushToDiskSync:NO];
    }
}

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

#pragma mark - Notification

- (void)applicationWillTerminateNotification:(NSNotification *)notification{
    [self flushToDiskSync:YES];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification{
    [self flushToDiskSync:NO];
}

- (void)exceptionHandlerNotification:(NSNotification *)notification{
    NSString *crashString = notification.object;
   [[DDLoggerClient sharedInstance] printfLog:crashString];
   [[DDLoggerClient sharedInstance] flushToDiskSync:YES];
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
            logMessage = [@"[ERROR] " stringByAppendingString:logMessage];
            break;
        case DDLogLevelWarning:
            logMessage = [@"[WARNING] " stringByAppendingString:logMessage];
            break;
        case DDLogLevelInfo:
            logMessage = [@"[INFO] " stringByAppendingString:logMessage];
            break;
        case DDLogLevelDebug: {
            logMessage = [@"[DEBUG] " stringByAppendingString:logMessage];
            break;
        default:
            break;
        }
    }
    NSString *formatLogString = [[DDLoggerClient sharedInstance] formatLogMessage:logMessage];
    [[DDLoggerClient sharedInstance] printfLog:formatLogString];
}