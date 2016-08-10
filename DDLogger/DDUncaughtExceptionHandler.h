//
//  DDUncaughtExceptionHandler.h
//  DDLoggerDemo
//
//  Created by lilingang on 8/10/16.
//  Copyright © 2016 LiLingang. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const DDExceptionHandlerNotification;

@interface DDUncaughtExceptionHandler : NSObject

+ (void)InstallUncaughtExceptionHandler;

@end
