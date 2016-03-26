//
//  DDLoggerManager.h
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#import <Foundation/Foundation.h>

/**
 *  @brief 本地log文件管理类
 */
@interface DDLoggerManager : NSObject

/**
 *  @brief 设置log缓存的绝对目录,默认Library/Caches/DDLogger
 */
@property (nonatomic, copy, readonly) NSString *cacheDirectory;
/**
 *  @brief 当前log日志文件路径
 */
@property (nonatomic, copy, readonly) NSString *currentLogFilePath;


/**
 *  @brief 唯一初始化方法
 *
 *  @return DDLoggerManager实例
 */
+ (DDLoggerManager *)sharedInstance;

/**
 *  @brief 配置缓存目录，默认Library/Caches/DDLogger
 *
 *  @param cacheDirectory 路径
 */
- (void)configCacheDirectory:(NSString *)cacheDirectory;

/**
 *  @brief 根据文件名获取log日志的完整路径
 *
 *  @param fileName log文件名
 *
 *  @return NSString 文件路径
 */
- (NSString *)filePathWithName:(NSString *)fileName;

/**
 *  @brief 获取本地缓存中所有的log文件名
 *
 *  @return NSArray
 */
- (NSArray *)getLogFileNames;

/**
 *  @brief 计算所有log日志的大小
 *
 *  @param completionBlock 回调 大小单位 bytes
 */
- (void)calculateSizeWithCompletionBlock:(void(^)(NSUInteger fileCount, NSUInteger totalSize))completionBlock;

/**
 *  @brief 清除本地log
 *
 *  @param usePolicy       YES ？按照预设的策略清理 ： 全部移除
 *  @param completionBlock 回调
 */
- (void)cleanDiskUsePolicy:(BOOL)usePolicy completionBlock:(void(^)())completionBlock;

@end
