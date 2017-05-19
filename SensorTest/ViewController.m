//
//  ViewController.m
//  SensorTest
//
//  Created by mac on 17/5/19.
//  Copyright © 2017年 cai. All rights reserved.
//

//CoreMotion框架: 加速计 陀螺仪 磁力计
/*
 加速计作用: 检测设备的摇晃
 摇一摇、计步器
 
 CoreMotion.framework
 获取数据两种方式:
 1.push 实时采集所有数据(采集频率高)
 步骤:
 1.创建运动管理者对象
 2.判断加速计是否可用
 3.设置采样间隔
 4.开始采样
 2.pull 有需要的时候 再主动采集数据
 
 计步器需要在plist中配置权限: 否则iOS10下崩溃
 <key>NSMotionUsageDescription</key>
	<string></string>
 也需要引入框架: #import <CoreMotion/CoreMotion.h>
 
 */

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>

#define SCREEN_Width    ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_Height   ([UIScreen mainScreen].bounds.size.height)

@interface ViewController ()

//运动管理者对象
@property (nonatomic, strong) CMMotionManager *motionManager;

//计步器 显示Label
@property (nonatomic, strong) UILabel *stepLabel;

@property (nonatomic, strong) CMPedometer *pedometer;

@end

@implementation ViewController

#pragma mark -
- (UILabel *)stepLabel
{
    if (!_stepLabel) {
        _stepLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 100, SCREEN_Width - 30, 100)];
        _stepLabel.backgroundColor = [UIColor cyanColor];
        _stepLabel.textColor = [UIColor purpleColor];
        _stepLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _stepLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor orangeColor];
    
    //距离传感器
    [self proximity];
    
    //加速计
//    [self accelerometerPull];
    
    [self accelerometerPush];
    
    //陀螺仪
    [self gyroPull];
    
//    [self gyroPush];
    
    //磁力计
    [self magnetometerPull];
    
//    [self magnetometerPush];
    
    //计步器
    [self.view addSubview:self.stepLabel];
    
    //计步器
    //判断硬件是否可用
    if (![CMPedometer isStepCountingAvailable]) {
        return;
    }
    
    //创建计步器类
    self.pedometer = [[CMPedometer alloc] init];
    
    //开始计步统计
    [self.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"error: %@", error);
            return ;
        }
        
        NSNumber *numberOfSteps = pedometerData.numberOfSteps;
        
        //主线程更新UI
        [self performSelectorOnMainThread:@selector(updateUI:) withObject:numberOfSteps waitUntilDone:NO];
        
    }];
}

//计步器
- (void)updateUI:(NSNumber *)number
{
    //可能不会实时显示数据
    self.stepLabel.text = [NSString stringWithFormat:@"一共走了%@步", number];
}

//距离传感器
- (void)proximity
{
    //开启距离传感器
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;// default is NO
    
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityStateDidChangeNotification) name:UIDeviceProximityStateDidChangeNotification object:nil];
}

#pragma mark -距离传感器通知方法
- (void)proximityStateDidChangeNotification
{
    //获取通知值
    if ([UIDevice currentDevice].proximityState) {
        //
        NSLog(@"有东西靠近");
    }else {
        NSLog(@"离开");
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //    //点击时获取加速计的值
    //    //运动管理器会记录所有的值在自己的属性中
    //    CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration;
    //
    //    NSLog(@"x: %f, y: %f, z: %f", acceleration.x, acceleration.y, acceleration.z);
    
    
    //    //点击时获取陀螺仪的值
    //    CMRotationRate rate = self.motionManager.gyroData.rotationRate;
    //    NSLog(@"x: %f, y: %f, z: %f", rate.x, rate.y, rate.z);
    
    //点击时获取磁力计的值
    //单位 特斯拉
    CMMagneticField field = self.motionManager.magnetometerData.magneticField;
    NSLog(@"x: %f, y: %f, z: %f", field.x, field.y, field.z);
    
}

//加速计
- (void)accelerometerPull
{
    //pull方式
    //创建
    _motionManager = [[CMMotionManager alloc] init];
    
    //是否可用
    if (![_motionManager isAccelerometerAvailable]) {
        return;
    }
    
    //开始采样
    [_motionManager startAccelerometerUpdates];
}

- (void)accelerometerPush
{
    //创建
    _motionManager = [[CMMotionManager alloc] init];
    
    //是否可用
    if (![_motionManager isAccelerometerAvailable]) {
        return;
    }
    
    //采样间隔  单位为秒  只有push方式需要采样间隔
    _motionManager.accelerometerUpdateInterval = 1;
    
    //开始采样
    [_motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        
        //获取data中数值
        //在哪个轴上 快速移动 哪个值就会改变
        CMAcceleration acceleration = accelerometerData.acceleration;
        
        NSLog(@"x: %f, y: %f, z: %f", acceleration.x, acceleration.y, acceleration.z);
    }];
}

//陀螺仪
- (void)gyroPush
{
    //陀螺仪push方式
    //创建
    _motionManager = [[CMMotionManager alloc] init];
    
    //是否可用
    if (![_motionManager isGyroAvailable]) {
        return;
    }
    
    //设置采样间隔    单位为秒
    self.motionManager.gyroUpdateInterval = 1;
    
    //开始采样
    [_motionManager startGyroUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        
        CMRotationRate rotationRate = gyroData.rotationRate;
        NSLog(@"x: %f, y: %f, z: %f", rotationRate.x, rotationRate.y, rotationRate.z);
        
    }];
}

- (void)gyroPull
{
    //陀螺仪pull方式
    //创建
    _motionManager = [[CMMotionManager alloc] init];
    
    //是否可用
    if (![_motionManager isGyroAvailable]) {
        return;
    }
    
    //开始采样
    [_motionManager startGyroUpdates];
}

//磁力计
- (void)magnetometerPull
{
    //磁力计pull方式
    //创建
    _motionManager = [[CMMotionManager alloc] init];
    
    //是否可用
    if (![_motionManager isMagnetometerAvailable]) {
        return;
    }
    
    //开始采样
    [_motionManager startMagnetometerUpdates];
}

- (void)magnetometerPush
{
    //创建
    _motionManager = [[CMMotionManager alloc] init];
    
    //是否可用
    if (![_motionManager isMagnetometerAvailable]) {
        return;
    }
    
    //采样间隔  单位为秒  只有push方式需要采样间隔
    _motionManager.magnetometerUpdateInterval = 1;
    
    //开始采样
    [_motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
        
        CMMagneticField field = magnetometerData.magneticField;
        NSLog(@"x: %f, y: %f, z: %f", field.x, field.y, field.z);
        
    }];
}

//摇一摇
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"摇一摇");
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"结束");
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"取消");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
