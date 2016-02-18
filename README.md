# DDLogger
a log redirect to file 

将NSLog替换为DDLog或者重新定义NSLog参见DDLog

##开始收集log只在applaunch的时候调用即可，且只需调用一次
##- (void)startLog;

##带参数的开始log收集
##- (void)startLogWithMaxLogAge:(NSUInteger)maxLogAge maxLogSize:(NSUInteger)maxLogSize cacheDirectory:(NSString *)cacheDirectory;


##停止收集log
##- (void)stopLog;

//*************log文件获取***************
##log存在的目录绝对目录
##- (NSString *)logDirectory;

##根据已存在的log名字返回相对路径
##- (NSString *)logFilePathWithFileName:(NSString *)fileName;

##获取本地所有的log列表
##- (NSArray *)getLogList:(NSError **)error;


//*************log输出显示查看***************
##当前是否显示logView
##- (BOOL)isShowLogView;

##显示logView
##- (void)showLogView;

##隐藏logView
##- (void)hidenLogView;
