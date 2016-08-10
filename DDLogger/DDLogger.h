//
//  DDLogger.h
//  Pods
//
//  Created by lilingang on 16/3/26.
//
//

#ifndef DDLogger_h
#define DDLogger_h
#import "DDLoggerClient.h"
#import "DDLoggerManager.h"

#define DDLogError(...)           DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelError,[NSString stringWithFormat:__VA_ARGS__]);
#define DDLogWarning(...)         DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelWarning,[NSString stringWithFormat:__VA_ARGS__]);
#define DDLog(...)                DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelInfo,[NSString stringWithFormat:__VA_ARGS__]);
#define DDLogDebug(...)           DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelDebug,[NSString stringWithFormat:__VA_ARGS__]);


#endif /* DDLogger_h */
