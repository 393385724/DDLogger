//
//  DDLogger.m
//  DDLoggerDemo
//
//  Created by 李林刚 on 2017/5/6.
//  Copyright © 2017年 LiLingang. All rights reserved.
//

#import "DDLogger.h"

#import "DDPlaintextLogger.h"
#import "DDEncryptLogger.h"
#import "DDLogConsoleView.h"
#import "DDLogListTableViewController.h"

static NSString * const DDLogDirectoryName              = @"log";

@interface DDLogger ()<DDLogListTableViewControllerDelegate, DDLogListTableViewControllerDataSoure>

@property (nonatomic, copy, readwrite) NSString *logDirectory;

@property (nonatomic, copy) NSString *logPathExtension;

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

- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix
                           encrypt:(BOOL)encrypt{
    [self startLogWithCacheDirectory:cacheDirectory nameprefix:nameprefix logPathExtension:@"log" maxDays:10 encrypt:encrypt];
}

- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix
                  logPathExtension:(NSString *)logPathExtension
                           maxDays:(NSUInteger)maxDays
                           encrypt:(BOOL)encrypt {
    NSAssert(cacheDirectory, @"cacheDirectory must not be nil");
    
    self.logPathExtension = logPathExtension;
    NSString *logDirectory = [cacheDirectory stringByAppendingPathComponent:DDLogDirectoryName];
    self.logDirectory = logDirectory;
    
    //旧log数据迁移
    NSArray *contentsOfDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheDirectory error:nil];
    for (NSString *fileName in contentsOfDirectory) {
        NSString *filePath = [cacheDirectory stringByAppendingPathComponent:fileName];
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([[attributesDictionary fileType] isEqualToString:NSFileTypeRegular] && [self isLogFileWithFileName:fileName]) {
            [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:[self filePathWithName:fileName] error:nil];
        }
    }
    
    self.encrypt = encrypt;
    if (self.encrypt) {
        [DDEncryptLogger setLogSuffix:[self getLogPathExtension] maxDays:maxDays];
        [DDEncryptLogger startLogWithCacheDirectory:self.logDirectory nameprefix:nameprefix];
    } else {
        [DDPlaintextLogger setLogSuffix:[self getLogPathExtension] fileCount:maxDays];
        [DDPlaintextLogger startLogWithCacheDirectory:self.logDirectory nameprefix:nameprefix];
    }
}

- (void)writeLogFile:(const char *)file
            function:(const char *)function
                line:(int)line
               level:(HMLogLevel)level
                 tag:(NSString *)tag
              format:(NSString *)format, ...{
    va_list ap;
    va_start (ap, format);
    if (self.encrypt) {
        [DDEncryptLogger writeLogFile:file function:function line:line level:level tag:tag format:format args:ap];
    } else {
        [DDPlaintextLogger writeLogFile:file function:function line:line level:level tag:tag format:format args:ap];
    }
    va_end (ap);
}

- (void)flushToDiskSync:(BOOL)sync{
    if (self.encrypt) {
        [DDEncryptLogger flushToDiskSync:sync];
    } else {
        [DDPlaintextLogger flushToDisk];
    }
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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

- (NSString *)getLogPathExtension {
    if (self.encrypt) {
        return [NSString stringWithFormat:@"hms%@",self.logPathExtension];
    } else {
        return self.logPathExtension;
    }
}

- (NSArray *)getLogFileNames{
    NSArray *contentsOfDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.logDirectory error:nil];
    NSMutableArray *logListArray = [[NSMutableArray alloc] init];
    for (NSString *fileName in contentsOfDirectory) {
        NSString *filePath = [self filePathWithName:fileName];
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([[attributesDictionary fileType] isEqualToString:NSFileTypeRegular] && [self isLogFileWithFileName:fileName]) {
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

- (NSString *)filePathWithName:(NSString *)fileName{
    return [self.logDirectory stringByAppendingPathComponent:fileName];
}

- (BOOL)isLogFileWithFileName:(NSString *)fileName{
    if ([[fileName pathExtension] isEqualToString:[self getLogPathExtension]] ||
        [[fileName pathExtension] isEqualToString:self.logPathExtension]) {
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
    [self flushToDiskSync:NO];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification{
    [self flushToDiskSync:YES];
}

@end
