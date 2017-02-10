# DDLogger
a log redirect to file ，建议使用最新版本

将NSLog替换为DDLog或者重新定义NSLog参见DDLog的定义可以在release模式下重向log到预先定义的日志目录
DDLoggerClient  log控制器
DDLoggerManager 本地log资源管理
使用方法：
前提使用的cocopods
pod 'DDLogger', '~> 1.2.5'

##开始收集log
>- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory fileName:(NSString *)fileName;
>
> >@code
> >
> >- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
> >
> >    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
> >    NSString *docDir = [paths objectAtIndex:0];
> >    [[DDLoggerClient sharedInstance] startLogWithCacheDirectory:docDir fileName:@"log.txt"];
> >
> >       return YES;
> >
> >}
> >
> >@endcode
> >

##停止收集log##
>- (void)stopLog;


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


#Iteration
#2016-11-02 fix flushToDiskSync crash -[__NSArrayM getObjects:range:]: range {0, 1} extends beyond bounds for empty array
#2016-02-10 change 1、可选对异常的捕捉 2、调整log宏 3、可在查看本地log的管理页面中删除指定的log文件