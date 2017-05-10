//
//  DDLogger.m
//  DDLoggerDemo
//
//  Created by 李林刚 on 2017/5/6.
//  Copyright © 2017年 LiLingang. All rights reserved.
//

#import "DDLogger.h"

#import <mars/xlog/xlogger.h>
#import <mars/xlog/appender.h>
#import <sys/xattr.h>
#import <pthread/pthread.h>

#import "DDPlaintextLogger.h"
#import "DDLogConsoleView.h"
#import "DDLogListTableViewController.h"

static NSString * const DDLogDirectoryName              = @"log";
static NSString * const DDEncryptLogPathExtension       = @"xlog";

@interface DDLogger ()<DDLogListTableViewControllerDelegate, DDLogListTableViewControllerDataSoure>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, copy, readwrite) NSString *logDirectory;

@property (nonatomic, assign) BOOL encrypt;

@property (nonatomic, strong) DDLogConsoleView *consoleView;

@property (nonatomic, copy) DDLoggerPikerEventHandler eventHandler;

@property (nonatomic, strong) DDPlaintextLogger *plaintextLogger;

@end

@implementation DDLogger

+ (DDLogger *)Logger{
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminateNotification:) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory nameprefix:(NSString *)nameprefix encrypt:(BOOL)encrypt{
    NSAssert(cacheDirectory, @"cacheDirectory must not be nil");
    //旧log数据迁移
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:cacheDirectory];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [cacheDirectory stringByAppendingPathComponent:fileName];
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([[attributesDictionary fileType] isEqualToString:NSFileType] && [self isLogFileWithFileName:fileName]) {
            [[NSFileManager defaultManager] moveItemAtPath:fileName toPath:[self filePathWithName:fileName] error:nil];
        }
    }
    
    NSString *logDirectory = [cacheDirectory stringByAppendingPathComponent:DDLogDirectoryName];
    // set do not backup for logpath
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    setxattr([logDirectory UTF8String], attrName, &attrValue, sizeof(attrValue), 0, 0);
    
    // init xlogger
#if DEBUG
    xlogger_SetLevel(kLevelAll);
    appender_set_console_log(true);
#else
    xlogger_SetLevel(kLevelInfo);
    appender_set_console_log(false);
#endif
    if (nameprefix) {
        appender_open(kAppednerAsync, [logDirectory UTF8String], nameprefix.UTF8String);
    } else {
        appender_open(kAppednerAsync, [logDirectory UTF8String], "");
    }
    
    self.encrypt = encrypt;
    self.logDirectory = logDirectory;
    
    if (!self.encrypt) {
        [self.plaintextLogger startLogWithCacheDirectory:self.logDirectory nameprefix:nameprefix];
    }
}

- (void)writeLogFile:(const char *)file
            function:(const char *)function
                line:(int)line
               level:(DDLogLevel)level
                 tag:(NSString *)tag
              format:(NSString *)format, ...{
    va_list ap;
    va_start (ap, format);
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    
    NSString *logString = [self formatLogFile:file function:function line:line level:level tag:tag LogMessage:body];
    if ([self isConsoleShow]) {
        [self.consoleView appendLog:logString];
    }
    if (self.encrypt) {
        TLogLevel tLevel = kLevelInfo;
        switch (level) {
            case DDLogLevelDebug:
                tLevel = kLevelDebug;
                break;
            case DDLogLevelInfo:
                tLevel = kLevelInfo;
                break;
            case DDLogLevelWarn:
                tLevel = kLevelWarn;
                break;
            case DDLogLevelError:
                tLevel = kLevelError;
                break;
            case DDLogLevelFatal:
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
    } else {
#ifdef DEBUG
#ifdef __IPHONE_9_0
        printf("%s\n",[logString UTF8String]);
#else
        NSLog(@"%@",logString);
#endif
        [self.plaintextLogger printfLog:logString];
#else
        if (level != DDLogLevelDebug) {
            [self.plaintextLogger printfLog:logString];
        }
#endif
    }
}

- (void)stopLog {
    if (!self.encrypt) {
        [self.plaintextLogger stopLog];
    }
    appender_close();
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

#pragma mark - log File

- (void)calculateSizeWithCompletionBlock:(void(^)(NSUInteger fileCount, NSUInteger totalSize))completionBlock{
    if (!completionBlock) {
        return;
    }
    @synchronized (self) {
        __weak __typeof(&*self)weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL), ^{
            NSUInteger fileCount = 0;
            NSUInteger totalSize = 0;
            NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:weakSelf.logDirectory];
            for (NSString *fileName in fileEnumerator) {
                NSString *filePath = [self filePathWithName:fileName];
                NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                if ([[attributesDictionary fileType] isEqualToString:NSFileTypeRegular] && [self isLogFileWithFileName:fileName]) {
                    totalSize += [attributesDictionary fileSize];
                    fileCount ++;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(fileCount, totalSize);
            });
        });
    }
}

- (NSArray *)getLogFileNames{
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.logDirectory];
    NSMutableArray *logListArray = [[NSMutableArray alloc] init];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [self filePathWithName:fileName];
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([[attributesDictionary fileType] isEqualToString:NSFileType] && [self isLogFileWithFileName:fileName]) {
            [logListArray addObject:fileName];
        }
    }
    return logListArray;
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
    logListViewController.dataSoure = [self getLogFileNames];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:logListViewController];
    [navigationController.navigationBar setTranslucent:NO];
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)flushToDiskSync:(BOOL)isSync{
    if (!self.encrypt) {
        [self.plaintextLogger flushToDiskSync:isSync];
    } else {
        if (isSync) {
            appender_flush_sync();
        } else {
            appender_flush();
        }
    }
}

- (NSString *)formatLogFile:(const char *)file
                   function:(const char *)function
                       line:(int)line
                      level:(DDLogLevel)level
                        tag:(NSString *)tag
                 LogMessage:(NSString *)message{
    NSProcessInfo* info = [NSProcessInfo processInfo];
    __uint64_t threadId;
    if (pthread_threadid_np(0, &threadId)) {
        threadId = pthread_mach_thread_np(pthread_self());
    }
    
    NSString *dateStr = [self.dateFormatter stringFromDate:[NSDate date]];
    NSString *logString = [NSString stringWithFormat:@"%@ %@[%d,%llu]", dateStr, info.processName, info.processIdentifier, threadId];
    switch (level) {
        case DDLogLevelDebug:
            logString = [logString stringByAppendingString:@"[D]"];
            break;
        case DDLogLevelInfo:
            logString = [logString stringByAppendingString:@"[I]"];
            break;
        case DDLogLevelWarn:
            logString = [logString stringByAppendingString:@"[W]"];
            break;
        case DDLogLevelError:
            logString = [logString stringByAppendingString:@"[E]"];
            break;
        case DDLogLevelFatal:
            logString = [logString stringByAppendingString:@"[F]"];
            break;
        default:
            break;
    }
    if (tag) {
        logString = [logString stringByAppendingFormat:@"[%@]",tag];
    } else {
        logString = [logString stringByAppendingString:@"[]"];
    }
    
    logString = [logString stringByAppendingString:@"["];
    NSString *fileName = @"";
    if (file != NULL) {
        NSString *fileString = [NSString stringWithUTF8String:file];
        fileName = [fileString lastPathComponent];
        logString = [logString stringByAppendingFormat:@"%@,",fileName.stringByDeletingPathExtension];
    }
    if (function != NULL) {
        NSString *functionString = [NSString stringWithUTF8String:function];
        NSArray *tmpArray = [functionString componentsSeparatedByString:@" "];
        NSString *lastString = [tmpArray lastObject];
        lastString = [lastString stringByReplacingOccurrencesOfString:@":]" withString:@""];
        logString = [logString stringByAppendingFormat:@" %@,",lastString];
    }
    if (line >= 0) {
        logString = [logString stringByAppendingFormat:@" %d",line];
    }
    logString = [logString stringByAppendingString:@"]"];
    
    logString = [logString stringByAppendingFormat:@"[%@\n",message];
    return logString;
}

- (NSString *)filePathWithName:(NSString *)fileName{
    return [self.logDirectory stringByAppendingPathComponent:fileName];
}

- (BOOL)isLogFileWithFileName:(NSString *)fileName{
    if ([[fileName pathExtension] isEqualToString:DDPlaintextLogPathExtension] || [[fileName pathExtension] isEqualToString:DDEncryptLogPathExtension]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - DDLogListTableViewControllerDataSoure

- (NSString *)logListTableViewController:(DDLogListTableViewController *)viewController logFilePathWithFileName:(NSString *)fileName{
    return [self filePathWithName:fileName];
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


#pragma mark - Notification

- (void)applicationWillTerminateNotification:(NSNotification *)notification{
    [self flushToDiskSync:YES];
    [self stopLog];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification{
    [self flushToDiskSync:NO];
}

#pragma mark - Getter and Setter

- (DDPlaintextLogger *)plaintextLogger {
    if (!_plaintextLogger) {
        _plaintextLogger = [[DDPlaintextLogger alloc] init];
    }
    return _plaintextLogger;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[NSLocale currentLocale ].localeIdentifier]];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return _dateFormatter;
}

@end
