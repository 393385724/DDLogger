//
//  AppDelegate.m
//  HMLoggerDemo
//
//  Created by 李林刚 on 2017/5/25.
//  Copyright © 2017年 huami. All rights reserved.
//

#import "AppDelegate.h"
#import "DDMainViewController.h"
#import "HMLogger.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    [[HMLogger Logger] startLogWithCacheDirectory:docDir nameprefix:@"hm" encrypt:NO];
    
    DDMainViewController *viewController = [[DDMainViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
