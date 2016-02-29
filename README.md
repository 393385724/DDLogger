# DDLogger
a log redirect to file 

将NSLog替换为DDLog或者重新定义NSLog参见DDLog的定义可以在release模式下重向log到预先定义的日志目录
使用方法：
前提使用的cocopods
pod 'DDLogger', '~> 1.0.1'

##开始收集log
>- (void)startLog;
>
> >@code
> >
> >- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
> >
> >      [[DDLogger sharedInstance] startLog];
> >
> >       return YES;
> >
> >}
> >
> >@endcode
> >

##开始收集log，并配置默认参数
>
>  @param maxLogAge      log保存在本地的最长时间， 单位/s，0代表使用默认值30天
>
>  @param maxLogSize     log在本地保存最大的空间，单位/bytes，0代表使用默认值100M
>
>  @param cacheDirectory log缓存的绝对目录，nil代表使用默认值Library/Caches/DDLog
>
>- (void)startLogWithMaxLogAge:(NSUInteger)maxLogAge maxLogSize:(NSUInteger)maxLogSize cacheDirectory:(NSString *)cacheDirectory;
>
> >@code
> >
> >- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
> >
> >        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
> >
> >        NSString *cacheDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"HMLOG"];
> >
> >        [[DDLogger sharedInstance] startLogWithMaxLogAge:60*60*24*7 maxLogSize:1024*1024*5 cacheDirectory:cacheDirectory]; 
> >
> >        return YES;
> >
> > }
> >
> > @endcode
> >

##停止收集log##
>- (void)stopLog;

##log存在的目录绝对目录
>- (NSString *)logDirectory;

##获取本地所有的log列表
>- (NSArray *)getLogList:(NSError **)error;


##当前是否显示logView
>- (BOOL)isShowLogView;

## 显示logView
>- (void)showLogView;

##隐藏logView
>- (void)hidenLogView;


##查看本地存在的log日志
>
>  @param viewController 当前的Viewontroller
>
>  @param handler        选取回调结果
>
>- (void)pikerLogWithViewController:(UIViewController *)viewController eventHandler:(DDPikerLogEventHandler)handler;
