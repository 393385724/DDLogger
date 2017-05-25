//
//  DDMainViewController.m
//  HMLoggerDemo
//
//  Created by lilingang on 16/2/29.
//  Copyright © 2016年 LiLingang. All rights reserved.
//

#import "DDMainViewController.h"
#import "HMLogger.h"

@interface DDMainViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation DDMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:tap];
}

- (void)tap:(UITapGestureRecognizer *)tap{
    [self.textView resignFirstResponder];
}

- (IBAction)showLogViewAction:(UIButton *)sender {
    if ([[HMLogger Logger] isConsoleShow]) {
        sender.titleLabel.text = @"log显示页面";
        [[HMLogger Logger] hidenConsole];
    } else {
        sender.titleLabel.text = @"关闭log显示页面";
        [[HMLogger Logger] showConsole];
    }
}
- (IBAction)viewLocalLogAction:(id)sender {
    [[HMLogger Logger] pikerLogWithViewController:self eventHandler:^(NSArray *logPathList) {
        [logPathList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[NSFileManager defaultManager] removeItemAtPath:obj error:nil];
        }];
    }];
}

- (IBAction)writeLogAction:(id)sender {
//    NSLog(@"NSLog 这是一条测试数据你能看到么这是一条测试数据你能看到么");
//    HMLogWarn(@"HMLogWarn 这是一条测试数据你能看到么这是一条测试数据你能看到么");
//    HMLogError(@"HMLogError 这是一条测试数据你能看到么这是一条测试数据你能看到么");
//    HMLogInfo(@"HMLogFatal 这是一条测试数据你能看到么这是一条测试数据你能看到么");
    
        NSDate *date = [NSDate date];
        for (NSInteger i = 0; i < 10000; i ++) {
            DDLogError(@"%ld 阿啊哀唉挨矮爱碍安岸按案暗昂袄傲奥八巴扒 吧疤拔把坝爸罢霸白百柏摆败拜班般斑搬板版 办半伴扮拌瓣帮绑榜膀傍棒包胞雹宝饱保堡报 抱暴爆杯悲碑北贝备背倍被辈奔本笨蹦逼鼻比 彼笔鄙币必毕闭毙弊碧蔽壁避臂边编鞭扁便变 辫辨辩辪辬表别宾滨冰兵丙柄饼并病拨波玻剥 脖菠播伯驳泊博搏膊薄卜补捕不布步怖部擦猜 才材财裁采彩睬踩菜参餐残蚕惭惨灿仓苍舱藏 操槽草册侧厕测策层叉插查茶察岔差拆柴馋缠 产铲颤昌长肠尝偿常厂场敞畅倡唱抄钞超朝潮 吵炒车扯彻撤尘臣沉辰陈晨闯衬称趁撑成呈承 池匙尺齿耻斥赤翅充冲诚城乘惩程秤吃驰迟持 臭出初除厨锄础储楚处虫崇抽仇绸愁稠筹酬丑 触畜川穿传船喘串疮窗床创吹炊垂锤春纯唇蠢 聪丛凑粗促醋窜催摧脆词慈辞磁此次刺从匆葱 大呆代带待怠贷袋逮戴翠村存寸错曾搭达答打 蛋当挡党荡档刀叨导岛丹单担耽胆旦但诞弹淡 倒蹈到悼盗道稻得德的灯登等凳低堤滴敌笛底 抵地弟帝递第颠典点电店垫殿叼雕吊钓调掉爹 跌叠蝶丁叮盯钉顶订定丢东冬董懂动冻栋洞都 斗抖陡豆逗督毒读独堵赌杜肚度渡端短段断缎 朵躲惰鹅蛾额恶饿恩儿锻堆队对吨蹲盾顿多夺 而耳二发乏伐罚阀法帆番翻凡烦繁反返犯泛饭 范贩方坊芳防妨房仿访纺放飞非肥匪废沸肺费 分吩纷芬坟粉份奋愤粪丰风封疯峰锋蜂逢缝讽 凤奉佛否夫肤伏扶服俘浮符幅福抚府斧俯辅腐 父付妇负附咐复赴副傅富腹覆该改盖溉概干甘 纲缸钢港杠高膏糕搞稿杆肝竿秆赶敢感冈刚岗 葛隔个各给根跟更耕工告哥胳鸽割搁歌阁革格 弓公功攻供宫恭躬巩共贡勾沟钩狗构购够估姑 孤辜古谷股骨鼓固故顾瓜刮挂乖拐怪关观官冠 馆管贯惯灌罐光广归龟规轨鬼柜贵桂跪滚棍锅 国果裹过哈孩海害含寒喊汉汗旱航毫豪好号浩 贺黑痕很狠恨恒横衡轰耗喝禾合何和河核荷盒 哄烘红宏洪虹喉猴吼后厚候乎呼忽狐胡壶湖糊 化划画话怀槐坏欢还环蝴虎互户护花华哗滑猾 晃谎灰恢挥辉回悔汇会缓幻唤换患荒慌皇黄煌 活火伙或货获祸惑击饥绘贿惠毁慧昏婚浑魂混 吉级即极急疾集籍几己圾机肌鸡迹积基绩激及 既济继寄加夹佳家嘉甲挤脊计记纪忌技际剂季 间肩艰兼监煎拣俭茧捡价驾架假嫁稼奸尖坚歼 健舰渐践鉴键箭江姜将减剪检简见件建剑荐贱 郊娇浇骄胶椒焦蕉角狡浆僵疆讲奖桨匠降酱交 皆接揭街节劫杰洁结捷绞饺脚搅缴叫轿较教阶 今斤金津筋仅紧谨锦尽截竭姐解介戒届界借巾 晶睛精井颈景警净径竞劲近进晋浸禁京经茎惊 酒旧救就舅居拘鞠局菊竟敬境静镜纠究揪九久 橘举矩句巨拒具俱剧惧据距锯聚捐卷倦绢决绝 觉掘嚼军君均菌俊卡开凯慨刊堪砍看康糠扛抗 炕考烤靠科棵颗壳咳可渴克刻客课肯垦恳坑空",(long)i);
        }
        NSLog(@"%f",[[NSDate date] timeIntervalSinceDate:date]);
}

//- (void)badAccess
//{
//    void (*nullFunction)() = NULL;
//    
//    nullFunction();
//}
@end
