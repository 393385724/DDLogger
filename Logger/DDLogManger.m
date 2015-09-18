//
//  DDLogManger.m
//  FitRunning
//
//  Created by lilingang on 15/9/18.
//  Copyright © 2015年 LiLingang. All rights reserved.
//

#import "DDLogManger.h"
#import "DDLogTool.h"

static NSString * const DDLogDirectoryName = @"DDLog";

static const NSInteger DDDefaultCacheMaxLogAge = 60 * 60 * 24 * 7; // 1 week

@interface DDLogManger ()

@property (nonatomic, strong) dispatch_queue_t logIOQueue;

@property (nonatomic, copy) NSString *cacheDirectory;

@property (nonatomic, copy) NSString *logFileName;

@end


@implementation DDLogManger

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.maxLogAge = DDDefaultCacheMaxLogAge;
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

- (NSString *)logFilePath{
    NSString *filePath = [self.cacheDirectory stringByAppendingPathComponent:self.logFileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    }
    return filePath;
}

- (NSArray *)getLogList{
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cacheDirectory error:nil];
}

- (void)calculateSizeWithCompletionBlock:(DDLogCalculateSizeBlock)completionBlock {
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
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(fileCount, totalSize);
            });
        }
    });
}

- (void)cleanDiskUsePolicy:(BOOL)usePolicy completionBlock:(DDLogNoParamsBlock)completionBlock {
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
        
        // Enumerate all of the files in the cache directory.  This loop has two purposes:
        //
        //  1. Removing files that are older than the expiration date.
        //  2. Storing file attributes for the size-based cleanup pass.
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:includingProperties error:NULL];
            
            // Skip directories.
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            
            // Remove files that are older than the expiration date;
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }
            
            // Store a reference to this file and account for its total size.
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += [totalAllocatedSize unsignedIntegerValue];
            [cacheFiles setObject:resourceValues forKey:fileURL];
        }
        
        for (NSURL *fileURL in urlsToDelete) {
            [fileManger removeItemAtURL:fileURL error:nil];
        }
        
        // If our remaining disk cache exceeds a configured maximum size, perform a second
        // size-based cleanup pass.  We delete the oldest files first.
        if (self.maxLogSize > 0 && currentCacheSize > self.maxLogSize) {
            // Target half of our maximum cache size for this cleanup pass.
            const NSUInteger desiredCacheSize = self.maxLogSize / 2;
            
            // Sort the remaining cache files by their last modification time (oldest first).
            NSArray *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                            usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                            }];
            
            // Delete files until we fall below our desired cache size.
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
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _cacheDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:DDLogDirectoryName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_cacheDirectory]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return _cacheDirectory;
}

- (NSString *)logFileName{
    if (!_logFileName) {
        NSString *dateStr = [DDLogTool getDateTimeStringWithFormat:@"yyyy-MM-dd"];
        _logFileName = [NSString stringWithFormat:@"%@.log",dateStr];
    }
    return _logFileName;
}

@end
