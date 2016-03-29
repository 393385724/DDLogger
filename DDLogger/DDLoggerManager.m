//
//  DDLoggerManager.m
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#import <UIKit/UIKit.h>
#import "DDLoggerManager.h"

static NSString * const DDLogDirectoryName = @"DDLogger";
static NSString * const DDLogPathExtension = @"log";
static const NSInteger DDLogDefaultCacheMaxAge = 60 * 60 * 24 * 30; // 30 Day
static const NSInteger DDLogDefaultCacheMaxSize = 1024 * 1024 * 100; // 100M

@interface DDLoggerManager ()
@property (nonatomic, strong) dispatch_queue_t logIOQueue;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, copy, readwrite) NSString *cacheDirectory;
@property (nonatomic, copy, readwrite) NSString *currentLogFilePath;
/**
 *  @brief log保存在本地的最长时间 单位/s 默认30Day
 */
@property (nonatomic, assign) NSInteger maxLogAge;

/**
 *  @brief log在本地保存最大的空间，单位/bytes 默认100M
 */
@property (nonatomic, assign) NSUInteger maxLogSize;
@end

@implementation DDLoggerManager

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (DDLoggerManager *)sharedInstance{
    static DDLoggerManager*_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DDLoggerManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.maxLogAge = DDLogDefaultCacheMaxAge;
        self.maxLogSize = DDLogDefaultCacheMaxSize;
        self.logIOQueue = dispatch_queue_create("com.ddlogger.cache", DISPATCH_QUEUE_SERIAL);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        self.cacheDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:DDLogDirectoryName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.cacheDirectory]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        self.currentLogFilePath = [self filePathWithName:[self currentDateFileName]];

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

- (void)configCacheDirectory:(NSString *)cacheDirectory{
    self.cacheDirectory = cacheDirectory;
    self.currentLogFilePath = [self filePathWithName:[self currentDateFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.cacheDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (NSString *)filePathWithName:(NSString *)fileName{
    return [self.cacheDirectory stringByAppendingPathComponent:fileName];
}

- (NSArray *)getLogFileNames{
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.cacheDirectory];
    NSMutableArray *logListArray = [[NSMutableArray alloc] init];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [self filePathWithName:fileName];
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([[attributesDictionary fileType] isEqualToString:NSFileTypeRegular] && [self isLogFileWithFileName:fileName]) {
            [logListArray addObject:fileName];
        }
    }
    return logListArray;
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

- (void)cleanDiskUsePolicy:(BOOL)usePolicy completionBlock:(void(^)())completionBlock{
    __weak __typeof(&*self)weakSelf = self;
    dispatch_async(self.logIOQueue, ^{
        if (!usePolicy) {
            NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:weakSelf.cacheDirectory];
            for (NSString *fileName in fileEnumerator) {
                NSString *filePath = [self filePathWithName:fileName];
                NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                if ([[attributesDictionary fileType] isEqualToString:NSFileTypeRegular] && [self isLogFileWithFileName:fileName]) {
                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                }
            }
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock();
                });
            }
            return;
        }
        NSURL *diskCacheURL = [NSURL fileURLWithPath:weakSelf.cacheDirectory isDirectory:YES];
        NSArray *includingProperties = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey,NSURLNameKey];
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
            //跳过不是log日志文件的
            if (![self isLogFileWithFileName:resourceValues[NSURLNameKey]]) {
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
 *  @brief 判断是不是log文件
 *
 *  @param fileName 文件名字
 *
 *  @return YES？是：不是
 */
- (BOOL)isLogFileWithFileName:(NSString *)fileName{
    if ([[fileName pathExtension] isEqualToString:DDLogPathExtension]) {
        return YES;
    } else {
        return NO;
    }
}

/**
 *  @brief 根据当前时间计算出来的文件名
 *
 *  @return NSString 文件名 yyyy-MM-dd
 */
- (NSString *)currentDateFileName{
    NSString *currentDateString = [self.dateFormatter stringFromDate:[NSDate date]];
    return [currentDateString stringByAppendingPathExtension:DDLogPathExtension];
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

- (NSDateFormatter *)dateFormatter{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[NSLocale currentLocale ].localeIdentifier]];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return _dateFormatter;
}
@end
