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

#ifdef DEBUG
#define NSLog(args...)                DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelNone,args);
#else
#define NSLog(args...)                while(0) {};
#endif


#define DDLogError(args...)           DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelError,args);
#define DDLogWarning(args...)         DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelWarning,args);
#define DDLog(args...)                DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelInfo,args);
#define DDLogDebug(args...)           DDExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,DDLogLevelDebug,args);


#endif /* DDLogger_h */
