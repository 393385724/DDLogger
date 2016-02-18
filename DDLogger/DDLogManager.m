//
//  DDLogManager.m
//  DDLogger
//
//  Created by lilingang on 15/9/18.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDLogManager.h"

static NSString * const DDLogDirectoryName = @"DDLog";
static const NSInteger DDLogDefaultCacheMaxAge = 60 * 60 * 24 * 30; // 30 Day
static const NSInteger DDLogDefaultCacheMaxSize = 1024 * 1024 * 100; // 100M

@interface DDLogManager ()
@property (nonatomic, strong) dispatch_queue_t logIOQueue;
@property (nonatomic, copy) NSString *logFileName;
@end

@implementation DDLogManager

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.maxLogAge = DDLogDefaultCacheMaxAge;
        self.maxLogSize = DDLogDefaultCacheMaxSize;
        self.logIOQueue = dispatch_queue_create("com.log.DDLogCache", DISPATCH_QUEUE_SERIAL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundCleanDisk)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)currentLogFilePath{
    NSString *filePath = [self.cacheDirectory stringByAppendingPathComponent:self.logFileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    }
    return filePath;
}

- (NSArray *)getLogList:(NSError **)error{
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cacheDirectory error:error];
}

- (void)calculateSizeWithCompletionBlock:(void(^)(NSUInteger fileCount, NSUInteger totalSize))completionBlock{
    if (!completionBlock) {
        return;
    }
    __weak __typeof(&*self)weakSelf = self;
    dispatch_async(self.logIOQueue, ^{
        NSUInteger fileCount = 0;
        NSUInteger totalSize = 0;
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:weakSelf.cacheDirectory];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [weakSelf.cacheDirectory stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            totalSize += [attrs fileSize];
            fileCount ++;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(fileCount, totalSize);
        });
    });
}

- (void)cleanDiskUsePolicy:(BOOL)usePolicy completionBlock:(void(^)())completionBlock{
    __weak __typeof(&*self)weakSelf = self;
    dispatch_async(self.logIOQueue, ^{
        if (!usePolicy) {
            [[NSFileManager defaultManager] removeItemAtPath:weakSelf.cacheDirectory error:nil];
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock();
                });
            }
            return;
        }
        NSURL *diskCacheURL = [NSURL fileURLWithPath:weakSelf.cacheDirectory isDirectory:YES];
        NSArray *includingProperties = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxLogAge];
        
        
        NSFileManager *fileManger = [NSFileManager defaultManager];
        // This enumerator prefetches useful properties for our cache files.
        NSDirectoryEnumerator *fileEnumerator = [fileManger enumeratorAtURL:diskCacheURL
                                                 includingPropertiesForKeys:includingProperties
                                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                                               errorHandler:NULL];
        
        NSMutableDictionary *cacheFiles = [NSMutableDictionary dictionary];
        NSUInteger currentCacheSize = 0;
        
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:includingProperties error:NULL];
            // 跳过目录
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            // 日期过期则加入待删除数组
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }
            // 计算未过期的日志占用的存贮空间并缓存
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += [totalAllocatedSize unsignedIntegerValue];
            [cacheFiles setObject:resourceValues forKey:fileURL];
        }
        // 删除策略外的日志
        for (NSURL *fileURL in urlsToDelete) {
            [fileManger removeItemAtURL:fileURL error:nil];
        }
        
        // 根据缓存空间策略 清理log
        if (currentCacheSize > self.maxLogSize) {
            // 超出预期 则保留最大值的一半
            const NSUInteger desiredCacheSize = self.maxLogSize / 2;
            
            // 根据日期排序
            NSArray *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                            usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                            }];
            
            // 删除较早的日志以保证所占空间在指定范围内
            for (NSURL *fileURL in sortedFiles) {
                if ([fileManger removeItemAtURL:fileURL error:nil]) {
                    NSDictionary *resourceValues = cacheFiles[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= [totalAllocatedSize unsignedIntegerValue];
                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
        }
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

#pragma mark - Private Methods

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

#pragma mark - Notification

- (void)cleanDisk {
    [self cleanDiskUsePolicy:YES completionBlock:nil];
}

- (void)backgroundCleanDisk {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    [self cleanDiskUsePolicy:YES completionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

#pragma mark - Getter and Setter

- (NSString *)cacheDirectory {
    if (!_cacheDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _cacheDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:DDLogDirectoryName];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:_cacheDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return _cacheDirectory;
}

- (NSString *)logFileName{
    if (!_logFileName) {
        NSString *dateStr = [self getDateTimeStringWithFormat:@"yyyy-MM-dd"];
        _logFileName = [NSString stringWithFormat:@"%@.log",dateStr];
    }
    return _logFileName;
}

@end
