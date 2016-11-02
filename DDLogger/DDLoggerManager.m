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
static const NSInteger DDLogDefaultCacheMaxAge = 60 * 60 * 24 * 7; // 7 Day
static const NSInteger DDLogDefaultCacheMaxSize = 1024 * 1024 * 50; // 50M

@interface DDLoggerManager ()
@property (nonatomic, strong) dispatch_queue_t logIOQueue;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, copy, readwrite) NSString *cacheDirectory;
@property (nonatomic, copy, readwrite) NSString *currentLogName;
@property (nonatomic, copy, readwrite) NSString *currentLogFilePath;
@property (nonatomic, assign) BOOL isBackgroundClean;
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
        self.isBackgroundClean = NO;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[NSLocale currentLocale ].localeIdentifier]];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];
        self.maxLogAge = DDLogDefaultCacheMaxAge;
        self.maxLogSize = DDLogDefaultCacheMaxSize;
        self.logIOQueue = dispatch_queue_create("com.ddlogger.clean", DISPATCH_QUEUE_SERIAL);
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

- (void)configCacheDirectory:(NSString *)cacheDirectory fileName:(NSString *)filename{
    self.cacheDirectory = cacheDirectory;
    self.currentLogName = filename;
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
    @synchronized (self) {
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
}

- (void)cleanDiskUsePolicy:(BOOL)usePolicy completionBlock:(void(^)())completionBlock{
    @synchronized (self) {
        __weak __typeof(&*self)weakSelf = self;
        dispatch_async(self.logIOQueue, ^{
            @autoreleasepool {
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
            }
        });
    }
}

#pragma mark - Private Methods

- (BOOL)isLogFileWithFileName:(NSString *)fileName{
    NSString *currentLogPathExtension = self.currentLogName.pathExtension;
    NSString *pathExtension = currentLogPathExtension ? currentLogPathExtension : DDLogPathExtension;
    if ([[fileName pathExtension] isEqualToString:pathExtension]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Notification

- (void)cleanDisk {
    [self cleanDiskUsePolicy:YES completionBlock:nil];
}

- (void)backgroundCleanDisk {
    if (self.isBackgroundClean) {
        return;
    }
    self.isBackgroundClean = YES;
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    __weak __typeof(&*self)weakSelf = self;
    [self cleanDiskUsePolicy:YES completionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        strongSelf.isBackgroundClean = NO;
    }];
}

#pragma mark - Getter and Setter
- (NSString *)cacheDirectory{
    if (!_cacheDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _cacheDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:DDLogDirectoryName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_cacheDirectory]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return _cacheDirectory;
}

- (NSString *)currentLogName{
    if (!_currentLogName) {
        NSString *currentDateString = [self.dateFormatter stringFromDate:[NSDate date]];
        return [currentDateString stringByAppendingPathExtension:DDLogPathExtension];
    }
    return _currentLogName;
}

- (NSString *)currentLogFilePath{
    if (!_currentLogFilePath) {
        _currentLogFilePath = [self filePathWithName:self.currentLogName];
    }
    return _currentLogFilePath;
}
@end
