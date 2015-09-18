//
//  DDLogger.m
//  FitRunning
//
//  Created by lilingang on 15/9/17.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import "DDLogger.h"
#import "DDLogTool.h"
#import "DDLogManger.h"


void UncaughtExceptionHandler(NSException* exception);

@interface DDLogger ()

@property (nonatomic, strong) DDLogManger *logManger;

@property (nonatomic, strong) NSFileHandle *writeLogFileHandle;

@end

@implementation DDLogger

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
        self.logManger = [[DDLogManger alloc] init];
    }
    return self;
}

#pragma mark - Public Methods

- (void)startLog{
    NSString *logFilePath = [self.logManger logFilePath];
    self.writeLogFileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    [self.writeLogFileHandle seekToEndOfFile];
    if (![DDLogTool shouldRedirect]) {
        return;
    }
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
}

- (void)stopLog{
    [self.writeLogFileHandle closeFile];
    self.writeLogFileHandle = nil;
    self.logManger = nil;
}


- (NSString *)logDirectory{
    return self.logManger.cacheDirectory;
}

- (NSString *)logFilePathWithFileName:(NSString *)fileName{
    return [self.logManger.cacheDirectory stringByAppendingPathComponent:fileName];
}

- (NSArray *)getLogList{
    return [self.logManger getLogList];
}

- (void)calculateSizeWithCompletionBlock:(DDLogCalculateSizeBlock)completionBlock{
    [self.logManger calculateSizeWithCompletionBlock:completionBlock];
}

- (void)cleanDiskUsePolicy:(BOOL)UsePolicy completionBlock:(DDLogNoParamsBlock)completionBlock{
    [self.logManger cleanDiskUsePolicy:YES completionBlock:completionBlock];
}

#pragma mark - Private Methods

- (void)logWithFile:(NSString *)file lineNumber:(int)lineNumber functionName:(NSString *)functionName body:(NSString *)body{
    NSString *fileName = [file lastPathComponent];
    NSString *logMessage = [NSString stringWithFormat:@"<%@ : %d %@> %@",fileName,lineNumber,functionName,body];
    NSString *logString = [DDLogTool formatLogMessage:logMessage];
    fprintf(stderr, "%s",[logString UTF8String]);
    if (![DDLogTool shouldRedirect]) {
        [self.writeLogFileHandle writeData:[logString dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)uncaughtExceptionHandler:(NSException *)exception{
    NSString *crashString = [DDLogTool formatExceptionHandler:exception];
    [self.writeLogFileHandle writeData:[crashString dataUsingEncoding:NSUTF8StringEncoding]];
    [self stopLog];
}

#pragma mark - Getter and Setter

- (void)setMaxLogAge:(NSInteger)maxLogAge{
    self.logManger.maxLogAge = maxLogAge;
}

- (NSInteger)maxLogAge{
    return self.logManger.maxLogAge;
}

- (void)setMaxLogSize:(NSUInteger)maxLogSize{
    self.logManger.maxLogSize = maxLogSize;
}

- (NSUInteger)maxLogSize{
    return self.logManger.maxLogSize;
}

@end

void ExtendNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...) {
    va_list ap;
    va_start (ap, format);
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    [[DDLogger sharedInstance] logWithFile:[NSString stringWithUTF8String:file] lineNumber:lineNumber functionName:[NSString stringWithUTF8String:functionName] body:body];
}

void UncaughtExceptionHandler(NSException* exception){
    [[DDLogger sharedInstance] uncaughtExceptionHandler:exception];
}