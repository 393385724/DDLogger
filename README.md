# DDLogger
https://github.com/393385724/HMLogger 最新版本，该版本不在提交了
a log redirect to file ，建议使用最新版本
2.0.0版本采用<a href="https://github.com/CocoaLumberjack/CocoaLumberjack">CocoaLumberjack</a>与<a href="https://github.com/Tencent/mars">Xlog</a>的简单封装，在这里感谢两个开源框架

警告：由于原有类名与CocoaLumberjack有冲突，故改变自身类名前缀为HM，工程中有解码脚本使用方法如下：
python  脚本路径/decode_mars_log_file.py 日志路径/日志名字.xlog

将NSLog替换为DDLog或者重新定义NSLog参见DDLog的定义可以在release模式下重向log到预先定义的日志目录
使用方法：
前提使用的cocopods
pod 'HMLogger', '~> 2.0.0'

##开始收集log
>- (void)startLogWithCacheDirectory:(NSString *)cacheDirectory
                        nameprefix:(NSString *)nameprefix
                           encrypt:(BOOL)encrypt;
>
> >@code
> >
> >- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
> >
> >    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
> >    NSString *docDir = [paths objectAtIndex:0];
> >    [[HMLogger Logger] startLogWithCacheDirectory:docDir nameprefix:@"hm" encrypt:NO];
> >
> >    return YES;
> >
> >}
> >
> >@endcode
> >

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
#2017-05-10 change 1、支持腾讯的Xlog框架，仍兼容老版本的log写入，日志管理也统一由xlog来管理 2、去掉对异常的捕获，建议使用第三方比如国内bugly 国外fabric
#2017-05-25 change 1、支持CocoaLumberjack框架，类库名字修改为HMLogger
