//
//  HMLoggerDefine.h
//  HMLoggerDemo
//
//  Created by 李林刚 on 2017/5/24.
//  Copyright © 2017年 LiLingang. All rights reserved.
//

#ifndef HMLoggerDefine_h
#define HMLoggerDefine_h

/**
 log打印的信息
 
 - HMLogLevelDebug:  调试信息
 - HMLogLevelInfo:   信息
 - HMLogLevelWarn:   警告
 - HMLogLevelError:  基本错误
 - HMLogLevelFatal:  致命错误
 */
typedef NS_ENUM(NSUInteger, HMLogLevel) {
    HMLogLevelDebug         = 0,
    HMLogLevelInfo          = 1,
    HMLogLevelWarn          = 2,
    HMLogLevelError         = 3,
    HMLogLevelFatal         = 4,
};

#endif /* HMLoggerDefine_h */
