//
//  DDLoggerClient.m
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#import "DDPlaintextLogger.h"
#import <UIKit/UIKit.h>
#import <pthread.h>

NSInteger const DDMaxMessageInMemoryCount = 30;
NSInteger const DDMaxMessageInMemorySize = 256.0; //KB

NSString * const DDPlaintextLogPathExtension     = @"log";


@interface DDPlaintextLogger ()

@property (nonatomic, copy) NSString *logDirectory;

@property (nonatomic, copy) NSString *nameprefix;
@property (nonatomic, copy) NSString *logFileName;

//用与缓存处理
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *memoryCaches;
@property (nonatomic, assign) CGFloat memoryCacheSize;
@property (nonatomic, assign) NSInteger memoryMaxLine;
@property (nonatomic, assign) float memoryMaxSize;

@end

@implementation DDPlaintextLogger

- (instancetype)init{
    self = [super init];
    if (self) {
        self.memoryMaxSize = DDMaxMessageInMemorySize;
        self.memoryMaxLine = DDMaxMessageInMemoryCount;
    }
    return self;
}

- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory nameprefix:(NSString *)nameprefix{
    self.serialQueue = dispatch_queue_create("com.ddlogger.writeQueue", DISPATCH_QUEUE_SERIAL);
    self.memoryCaches = [[NSMutableArray alloc] initWithCapacity:DDMaxMessageInMemoryCount];
    
    self.nameprefix = nameprefix;
    self.logDirectory = cacheDirectory;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.logDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.logDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)printfLog:(NSString *)log{
    if (!self.memoryCaches ||
        !self.serialQueue) {
        return;
    }
    if (log) {
        //2016-10-9 try to fix flushToDiskSync crash -[__NSArrayM getObjects:range:]: range {0, 1} extends beyond bounds for empty array
        @synchronized (self.memoryCaches) {
            [self.memoryCaches addObject:log];
        }
    }
    self.memoryCacheSize += [log length]/1024.0;
    if ([self.memoryCaches count] >= self.memoryMaxLine ||
        self.memoryCacheSize >= self.memoryMaxSize) {
        [self flushToDiskSync:NO];
    }
}

- (void)flushToDiskSync:(BOOL)isSync{
    //2016-11-02 try to fix flushToDiskSync crash -[__NSArrayM getObjects:range:]: range {0, 1} extends beyond bounds for empty array
    @synchronized (self.memoryCaches) {
        if ([self.memoryCaches count] == 0 ||
            !self.memoryCaches) {
            NSLog(@"no more log in memory");
            return;
        }
        self.memoryMaxSize = 0.0;
        NSArray *readyToDiskMessageArray = [NSArray arrayWithArray:self.memoryCaches];
        [self.memoryCaches removeAllObjects];
        
        dispatch_block_t block = ^{
            NSString *logFilePath = [self.logDirectory stringByAppendingPathComponent:self.logFileName];
            const char *filePath = [logFilePath cStringUsingEncoding:NSASCIIStringEncoding];
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
}

- (void)stopLog{
    [self flushToDiskSync:NO];
    self.memoryCaches = nil;
    self.serialQueue = nil;
}

#pragma mark - Private Methods

- (NSString *)logFileName{
    if (!_logFileName) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[NSLocale currentLocale ].localeIdentifier]];
        [dateFormatter setDateFormat:@"yyyyMMdd"];
        NSString *currentDateString = [dateFormatter stringFromDate:[NSDate date]];
        if (self.nameprefix) {
            currentDateString = [NSString stringWithFormat:@"%@_%@",self.nameprefix,currentDateString];
        } else {
            currentDateString = [@"_" stringByAppendingString:currentDateString];
        }
        return [currentDateString stringByAppendingPathExtension:DDPlaintextLogPathExtension];
    }
    return _logFileName;
}

@end
