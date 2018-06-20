//
//  FQQRCodeScanViewController.m
//  FQQRCodeScanDemo
//
//  Created by mac on 2018/6/20.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "FQQRCodeScanViewController.h"
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <Photos/PHPhotoLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "UIImage+FQExtension.h"

#define kFlash_Y_PAD(__VALUE__) [UIScreen mainScreen].bounds.size.width / 320 * __VALUE__
/** 弱引用 */
#define WeakType(type) __weak typeof(type) weak##type = type;

@interface FQQRCodeScanViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCaptureMetadataOutputObjectsDelegate, UIGestureRecognizerDelegate>
{
    BOOL _delayQRAction;
    BOOL _delayBarAction;
}
@property (strong, nonatomic) AVCaptureDevice            *device;
@property (strong, nonatomic) AVCaptureDeviceInput       *input;
@property (strong, nonatomic) AVCaptureMetadataOutput    *output;
@property (strong, nonatomic) AVCaptureSession           *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;

/** app名字 */
@property (nonatomic, copy) NSString *appName;

/** 扫描视图 */
@property (nonatomic, strong) FQQRCodeScanView *scanRectView;

@property (nonatomic) CGRect scanRect;

/** 修改扫码类型按钮 */
@property (nonatomic, strong) UIButton *scanTypeQrBtn;
/** 修改扫码类型按钮 */
@property (nonatomic, strong) UIButton *scanTypeBarBtn;
/** 修改扫码从相册选择按钮 */
@property (nonatomic, strong) UIButton *scanTypeFromAblumBtn;

@property (nonatomic, copy) void (^scanFinish)(NSString *, NSError *);

@property (nonatomic, assign) FQQRCodeScanType scanType;



@end

@implementation FQQRCodeScanViewController

- (instancetype)initWithQrType:(FQQRCodeScanType)type onFinish:(void (^)(NSString *, NSError *))finish
{
    if (self = [super init]) {
        self.scanType = type;
        self.scanFinish = finish;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"扫码";
    _delayQRAction = NO;
    _delayBarAction = NO;
    self.appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (self.appName == nil || self.appName.length == 0) {
        self.appName = @"该App";
    }
    /// 获取扫码设备权限
    [self setupScanDevide];
    /// 添加扫码区域下方文字
    [self addScanViewTitle];
    /// 添加扫码区域中的闪光灯按钮
    [self addScanViewFlashButton];
    /// 初始化扫码区域
    [self initScanView];
    /// 初始化扫码类型
    [self initScanType];
    /// 初始化navi上的相册按钮
    [self initRightNaviButton:self.scanType];
    
}

- (void)initRightNaviButton:(FQQRCodeScanType)type
{
    if(type == FQQRCodeScanTypeBarCode) {
        [self.navigationItem setRightBarButtonItem:nil];
    } else {
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(photoAblumClick)];
        [self.navigationItem setRightBarButtonItem:rightItem];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //开始捕获
    if (self.session) [self.session startRunning];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 打开系统右滑移动返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;      // 手势有效设置为YES  无效为NO
        self.navigationController.interactivePopGestureRecognizer.delegate = self;    // 手势的代理设置为self
    }
    //开始捕获
    if (self.session) [self.session stopRunning];
}

#pragma mark ============ 生成二维码背景图片 ============

/**
 生成二维码【白底黑色】
 
 */
+ (UIImage*)createQRImageWithString:(NSString*)content QRSize:(CGSize)size
{
    NSData *stringData = [content dataUsingEncoding: NSUTF8StringEncoding];
    
    //生成
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    CIImage *qrImage = qrFilter.outputImage;
    //绘制
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(cgImage);
    
    return codeImage;
}


/**
 生成二维码【自定义颜色】
 
 */
+ (UIImage* )createQRImageWithString:(NSString*)content QRSize:(CGSize)size QRColor:(UIColor*)qrColor bkColor:(UIColor*)bkColor
{
    NSData *stringData = [content dataUsingEncoding: NSUTF8StringEncoding];
    //生成
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    //上色
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"
                                       keysAndValues:
                             @"inputImage",qrFilter.outputImage,
                             @"inputColor0",[CIColor colorWithCGColor:qrColor.CGColor],
                             @"inputColor1",[CIColor colorWithCGColor:bkColor.CGColor],
                             nil];
    CIImage *qrImage = colorFilter.outputImage;
    //绘制
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(cgImage);
    
    return codeImage;
}

/**
 *  生成二维码中间带logo
 */
+ (UIImage*)createQRImageWithString:(NSString*)content QRSize:(CGSize)size centerLogoImage:(UIImage *)logoImage logoBorderColor:(UIColor *)logoBorderColor
{
    NSData *stringData = [content dataUsingEncoding: NSUTF8StringEncoding];
    
    //生成
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    CIImage *qrImage = qrFilter.outputImage;
    //绘制
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(cgImage);
    /// 生成带logo的二维码
    codeImage = [UIImage imagewithBgImage:codeImage addLogoImage:logoImage ofTheSize:size];
    
    return codeImage;
}

#pragma mark ============ 生成条形码背景图片 ============
/**
 生成条形码【白底黑色】
 
 */
+ (UIImage *)createBarCodeImageWithString:(NSString *)content barSize:(CGSize)size
{
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    [filter setValue:data forKey:@"inputMessage"];
    CIImage *qrImage = filter.outputImage;
    //绘制
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(cgImage);
    
    return codeImage;
}


/**
 生成条形码【自定义颜色】

 */
+ (UIImage* )createBarCodeImageWithString:(NSString*)content QRSize:(CGSize)size QRColor:(UIColor*)qrColor bkColor:(UIColor*)bkColor
{
    NSData *stringData = [content dataUsingEncoding: NSUTF8StringEncoding];
    //生成
    CIFilter *barFilter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    [barFilter setValue:stringData forKey:@"inputMessage"];
    
    //上色
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"
                                       keysAndValues:
                             @"inputImage",barFilter.outputImage,
                             @"inputColor0",[CIColor colorWithCGColor:qrColor.CGColor],
                             @"inputColor1",[CIColor colorWithCGColor:bkColor.CGColor],
                             nil];
    
    CIImage *qrImage = colorFilter.outputImage;
    //绘制
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(cgImage);
    
    return codeImage;
}



#pragma mark ============ 获取扫码设备权限 ============
- (void)setupScanDevide
{
    if ([self isAvailableCamera]) {
        //初始化摄像设备
        self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        //初始化摄像输入流
        self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
        //初始化摄像输出流
        self.output = [[AVCaptureMetadataOutput alloc] init];
        //设置输出代理，在主线程里刷新
        [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        //初始化链接对象
        self.session = [[AVCaptureSession alloc] init];
        //设置采集质量
        [self.session setSessionPreset:AVCaptureSessionPresetInputPriority];
        //将输入输出流对象添加到链接对象
        if ([self.session canAddInput:self.input]) [self.session addInput:self.input];
        if ([self.session canAddOutput:self.output]) [self.session addOutput:self.output];
        
        //设置扫码支持的编码格式【默认二维码】
        self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        //设置扫描聚焦区域
        self.output.rectOfInterest = _scanRect;
        
        self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.preview.frame = [UIScreen mainScreen].bounds;
        [self.view.layer insertSublayer:self.preview atIndex:0];
    }
}

#pragma mark ============ 添加扫码区域下方文字 ============
- (void)addScanViewTitle
{
    if (!_tipTitle) {
        
        self.tipTitle = [[UILabel alloc]init];
        _tipTitle.bounds = CGRectMake(0, 0, 300, 50);
        _tipTitle.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, self.view.center.y + self.view.frame.size.width/2 - 35);
        _tipTitle.font = [UIFont systemFontOfSize:13];
        _tipTitle.textAlignment = NSTextAlignmentCenter;
        _tipTitle.numberOfLines = 0;
        _tipTitle.text = @"将取景框对准二维码,即可自动扫描";
        _tipTitle.textColor = [UIColor whiteColor];
        [self.view addSubview:_tipTitle];
        
    }
    _tipTitle.layer.zPosition = 1;
    [self.view bringSubviewToFront:_tipTitle];
    
}

#pragma mark ============ 添加扫码区域中的闪光灯按钮 ============
- (void)addScanViewFlashButton
{
    if (_flashBtn) {
        return;
    }
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"resource" ofType: @"bundle"]];
    
    self.flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_flashBtn setBounds:CGRectMake(0, 0, 60, 50)];
    [_flashBtn setCenter:CGPointMake(self.view.center.x, self.view.center.y + kFlash_Y_PAD(70))];
    [_flashBtn setImage:[UIImage imageNamed:@"scan_flash_normal" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [_flashBtn setImage:[UIImage imageNamed:@"scan_flash_select" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [_flashBtn setTitle:@"轻触照亮" forState:UIControlStateNormal];
    [_flashBtn setTitle:@"轻触关闭" forState:UIControlStateSelected];
    [_flashBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_flashBtn setTitleColor:[UIColor colorWithRed:0.161 green:0.659 blue:0.882 alpha:1.00] forState:UIControlStateSelected];
    [_flashBtn addTarget:self action:@selector(openFlash:) forControlEvents:UIControlEventTouchDown];
    _flashBtn.titleLabel.font = [UIFont systemFontOfSize:11];
    // button标题的偏移量以及图片的偏移量，以便于上下呈现
    _flashBtn.titleEdgeInsets = UIEdgeInsetsMake(
                                                 _flashBtn.imageView.frame.size.height+5,
                                                 -_flashBtn.imageView.bounds.size.width,
                                                 0,
                                                 0
                                                 );
    _flashBtn.imageEdgeInsets = UIEdgeInsetsMake(
                                                 0,
                                                 _flashBtn.titleLabel.frame.size.width/2,
                                                 _flashBtn.titleLabel.frame.size.height+5,
                                                 -_flashBtn.titleLabel.frame.size.width/2
                                                 );
    
    [self.view addSubview:_flashBtn];
    
}

#pragma mark ============ 闪光灯开启和关闭 ============
- (void)openFlash:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    AVCaptureDevice *device =  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device hasTorch] && [device hasFlash])
    {
        AVCaptureTorchMode torch = self.input.device.torchMode;
        
        switch (_input.device.torchMode) {
            case AVCaptureTorchModeAuto:
                break;
            case AVCaptureTorchModeOff:
                torch = AVCaptureTorchModeOn;
                break;
            case AVCaptureTorchModeOn:
                torch = AVCaptureTorchModeOff;
                break;
            default:
                break;
        }
        
        [_input.device lockForConfiguration:nil];
        _input.device.torchMode = torch;
        [_input.device unlockForConfiguration];
    }
    
}

#pragma mark ============ 初始化扫码区域 ============
- (void)initScanView
{
    _scanRectView = [[FQQRCodeScanView alloc] initWithFrame:self.view.frame style:@""];
    [_scanRectView setScanType:self.scanType];
    [self.view addSubview:_scanRectView];
    
    
}

#pragma mark ============ 初始化扫码类型 ============
- (void)initScanType
{
    if (self.scanType == FQQRCodeScanTypeAll) {
        _scanRect = CGRectFromString([self scanRectWithScale:1][0]);
        self.output.rectOfInterest = _scanRect;
        /// 添加扫描区域下方工具栏
        [self addScanViewBottomItems];
    } else if (self.scanType == FQQRCodeScanTypeQrCode) {
        self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        self.title = @"二维码";
        _scanRect = CGRectFromString([self scanRectWithScale:1][0]);
        self.output.rectOfInterest = _scanRect;
        _tipTitle.text = @"将取景框对准二维码,即可自动扫描";
        
        _tipTitle.center = CGPointMake(self.view.center.x, self.view.center.y + CGSizeFromString([self scanRectWithScale:1][1]).height/2 + 25);
        
    } else if (self.scanType == FQQRCodeScanTypeBarCode) {
        self.output.metadataObjectTypes = @[AVMetadataObjectTypeEAN13Code,
                                            AVMetadataObjectTypeEAN8Code,
                                            AVMetadataObjectTypeCode128Code];
        self.title = @"条码";
        
        _scanRect = CGRectFromString([self scanRectWithScale:3][0]);
        self.output.rectOfInterest = _scanRect;
        [self.scanRectView setScanType: FQQRCodeScanTypeBarCode];
        _tipTitle.text = @"将取景框对准条码,即可自动扫描";
        
        _tipTitle.center = CGPointMake(self.view.center.x, self.view.center.y + CGSizeFromString([self scanRectWithScale:3][1]).height/2 + 25);
        [_flashBtn setCenter:CGPointMake(self.view.center.x, CGRectGetMaxY(self.view.frame)- kFlash_Y_PAD(120))];
    }
    [self.view bringSubviewToFront:_tipTitle];
    [self.view bringSubviewToFront:_flashBtn];
}

#pragma mark ============ 添加扫描区域下方工具栏 ============
- (void)addScanViewBottomItems
{
    if (_toolsView) {
        return;
    }
    
    self.toolsView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.frame)-64,CGRectGetWidth(self.view.frame), 64)];
    if ([UIScreen mainScreen].bounds.size.height >= 812) {
        [self.toolsView setBounds:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 64 + 34)];
    }
    _toolsView.backgroundColor = [UIColor colorWithRed:0.212 green:0.208 blue:0.231 alpha:1.00];
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"resource" ofType: @"bundle"]];
    CGSize size = CGSizeMake([UIScreen mainScreen].bounds.size.width/3, 64);
    
    self.scanTypeQrBtn = [[UIButton alloc]init];
    _scanTypeQrBtn.frame = CGRectMake(0, 0, size.width, 64);
    [_scanTypeQrBtn setTitle:@"二维码" forState:UIControlStateNormal];
    [_scanTypeQrBtn setTitleColor:[UIColor colorWithRed:0.165 green:0.663 blue:0.886 alpha:1.00] forState:UIControlStateSelected];
    [_scanTypeQrBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_scanTypeQrBtn setImage:[UIImage imageNamed:@"scan_qr_normal" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [_scanTypeQrBtn setImage:[UIImage imageNamed:@"scan_qr_select" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [_scanTypeQrBtn setSelected:YES];
    _scanTypeQrBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 15);
    _scanTypeQrBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    [_scanTypeQrBtn addTarget:self action:@selector(qrBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.scanTypeFromAblumBtn = [[UIButton alloc]init];
    _scanTypeFromAblumBtn.frame = CGRectMake(size.width, 0, size.width, 64);
    [_scanTypeFromAblumBtn setTitle:@"相册" forState:UIControlStateNormal];
    [_scanTypeFromAblumBtn setTitleColor:[UIColor colorWithRed:0.165 green:0.663 blue:0.886 alpha:1.00] forState:UIControlStateSelected];
    [_scanTypeFromAblumBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_scanTypeFromAblumBtn setImage:[UIImage imageNamed:@"scan_ablum_normal" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [_scanTypeFromAblumBtn setImage:[UIImage imageNamed:@"scan_ablum_select" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [_scanTypeFromAblumBtn setSelected:NO];
    _scanTypeFromAblumBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 15);
    _scanTypeFromAblumBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    [_scanTypeFromAblumBtn addTarget:self action:@selector(photoAblumClick) forControlEvents:UIControlEventTouchUpInside];
    
    self.scanTypeBarBtn = [[UIButton alloc]init];
    _scanTypeBarBtn.frame = CGRectMake(2*size.width, 0, size.width, 64);
    [_scanTypeBarBtn setTitle:@"条形码" forState:UIControlStateNormal];
    [_scanTypeBarBtn setTitleColor:[UIColor colorWithRed:0.165 green:0.663 blue:0.886 alpha:1.00] forState:UIControlStateSelected];
    [_scanTypeBarBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_scanTypeBarBtn setImage:[UIImage imageNamed:@"scan_bar_normal" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [_scanTypeBarBtn setImage:[UIImage imageNamed:@"scan_bar_select" inBundle:bundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [_scanTypeBarBtn setSelected:NO];
    _scanTypeBarBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 15);
    _scanTypeBarBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    [_scanTypeBarBtn addTarget:self action:@selector(barBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [_toolsView addSubview:_scanTypeQrBtn];
    [_toolsView addSubview:_scanTypeFromAblumBtn];
    [_toolsView addSubview:_scanTypeBarBtn];
    [self.view addSubview:_toolsView];
}

#pragma mark ============ 点击二维码 ============
- (void)qrBtnClicked:(UIButton *)sender
{
    if (sender.selected) {
        return;
    }
    if (_delayQRAction) {
        return;
    }
    
    [sender setSelected:YES];
    [_scanTypeBarBtn setSelected:NO];
    [_scanTypeFromAblumBtn setSelected:NO];

    [self changeScanCodeType:FQQRCodeScanTypeQrCode];
    _delayQRAction = YES;
    [self initRightNaviButton:FQQRCodeScanTypeQrCode];

    [self performAfterTimeInterval:1.5f action:^{
        _delayQRAction = NO;
    }];
    
}

#pragma mark ============ 点击条形码 ============
- (void)barBtnClicked:(UIButton *)sender
{
    if (sender.selected) {
        return;
    }
    if (_delayBarAction) {
        return;
    }
    
    [sender setSelected:YES];
    [_scanTypeQrBtn setSelected:NO];
    [_scanTypeFromAblumBtn setSelected:NO];
    
    [self changeScanCodeType:FQQRCodeScanTypeBarCode];
    _delayBarAction = YES;
    [self initRightNaviButton:FQQRCodeScanTypeBarCode];

    [self performAfterTimeInterval:1.5f action:^{
        _delayBarAction = NO;
    }];
}

#pragma mark ============ 切换扫码类型 ============
- (void)changeScanCodeType:(FQQRCodeScanType)type
{
    [self.session stopRunning];
    __weak typeof (self)weakSelf = self;
    CGSize scanSize = CGSizeFromString([self scanRectWithScale:1][1]);
    if (type == FQQRCodeScanTypeBarCode) {
        self.output.metadataObjectTypes = @[AVMetadataObjectTypeEAN13Code,
                                            AVMetadataObjectTypeEAN8Code,
                                            AVMetadataObjectTypeCode128Code];
        self.title = @"条码";
        _scanRect = CGRectFromString([weakSelf scanRectWithScale:3][0]);
        scanSize = CGSizeFromString([self scanRectWithScale:3][1]);
    } else {
        self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        self.title = @"二维码";
        _scanRect = CGRectFromString([weakSelf scanRectWithScale:1][0]);
        scanSize = CGSizeFromString([self scanRectWithScale:1][1]);
    }
    
    
    //设置扫描聚焦区域
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.output.rectOfInterest = _scanRect;
        [weakSelf.scanRectView setScanType: type];
        _tipTitle.text = type == FQQRCodeScanTypeQrCode ? @"将取景框对准二维码,即可自动扫描" : @"将取景框对准条码,即可自动扫描";
        [weakSelf.session startRunning];
    });
    
    [UIView animateWithDuration:0.3 animations:^{
        _tipTitle.center = CGPointMake(self.view.center.x, self.view.center.y + scanSize.height/2 + 25);
        [_flashBtn setCenter:CGPointMake(self.view.center.x, type == FQQRCodeScanTypeQrCode ? (self.view.center.y + kFlash_Y_PAD(70)) : CGRectGetMaxY(self.view.frame)- kFlash_Y_PAD(120))];
    }];
    
    if ([_flashBtn isSelected]) {
        _flashBtn.selected = !_flashBtn.selected;
    }
    
    
}

#pragma mark ============ 点击相册 ============
- (void)photoAblumClick
{
    
    if ([self isAvailablePhoto]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    }else{
        NSString *tipMessage = [NSString stringWithFormat:@"请到手机系统的\n【设置】->【隐私】->【相册】\n对%@开启相机的访问权限",self.appName];
        [self showError:tipMessage andTitle:@"相册读取权限未开启"];
    }
    
}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    __block UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (!image){
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    [self recognizeQrCodeImage:image onFinish:^(NSString *result) {
        [self renderUrlStr:result];
    }];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"cancel");
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark ============ 相册选择二维码扫码 ============

+ (void)recognizeQrCodeImage:(UIImage *)image onFinish:(void (^)(NSString *))finish
{
    [[[FQQRCodeScanViewController alloc] init] recognizeQrCodeImage:image onFinish:finish];
}

- (void)recognizeQrCodeImage:(UIImage *)image onFinish:(void (^)(NSString *result))finish {
    
    if ([[[UIDevice currentDevice]systemVersion]floatValue] < 8.0 ) {
        
        [self showError:@"只支持iOS8.0以上系统"];
        return;
    }
    
    //系统自带识别方法
    CIContext *context = [CIContext contextWithOptions:nil];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    if (features.count >=1)
    {
        CIQRCodeFeature *feature = [features objectAtIndex:0];
        NSString *scanResult = feature.messageString;
        if (finish) {
            finish(scanResult);
        }
    } else {
        [self showError:@"图片中未识别到二维码"];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if ( (metadataObjects.count==0) )
    {
        [self showError:@"图片中未识别到二维码"];
        return;
    }
    
    if (metadataObjects.count>0) {
        [self.session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
        [self renderUrlStr:metadataObject.stringValue];
    }
}

#pragma mark ============ 扫码成功回调 ============
- (void)renderUrlStr:(NSString *)url {
    
    //输出扫描字符串
    if (self.scanFinish) {
        //回调结果到页面上，也可以在此处做跳转操作,如果不想回去，直接注释下面的代码
        if (self.navigationController &&[self.navigationController respondsToSelector:@selector(popViewControllerAnimated:)]) {
            [self.navigationController popViewControllerAnimated:YES];
            self.scanFinish(url, nil);
        }
    }
}

- (NSArray *)scanRectWithScale:(NSInteger)scale
{
    CGSize windowSize = [UIScreen mainScreen].bounds.size;
    CGFloat Left = 60 / scale;
    CGSize scanSize = CGSizeMake(self.view.frame.size.width - Left * 2, (self.view.frame.size.width - Left * 2) / scale);
    CGRect scanRect = CGRectMake((windowSize.width-scanSize.width)/2, (windowSize.height-scanSize.height)/2, scanSize.width, scanSize.height);
    
    scanRect = CGRectMake(scanRect.origin.y/windowSize.height, scanRect.origin.x/windowSize.width, scanRect.size.height/windowSize.height,scanRect.size.width/windowSize.width);
    
    return @[NSStringFromCGRect(scanRect), NSStringFromCGSize(scanSize)];
}

#pragma mark ============ 是否可以调用相册权限 ============
- (BOOL)isAvailablePhoto
{
    PHAuthorizationStatus authorStatus = [PHPhotoLibrary authorizationStatus];
    if ( authorStatus == PHAuthorizationStatusDenied ) {
        
        return NO;
    }
    return YES;
    
}

#pragma mark ============ 是否可以调用相机权限 ============
- (BOOL)isAvailableCamera
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        /// 用户是否允许摄像头使用
        NSString * mediaType = AVMediaTypeVideo;
        AVAuthorizationStatus  authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
        /// 不允许弹出提示框
        if (authorizationStatus == AVAuthorizationStatusRestricted ||
            authorizationStatus == AVAuthorizationStatusDenied) {
            NSString *tipMessage = [NSString stringWithFormat:@"请到手机系统的\n【设置】->【隐私】->【相机】\n对%@开启相机的访问权限",self.appName];
            [self showError:tipMessage andTitle:@"相机权限未开启"];
            
            return NO;
        }else{
            return  YES;
        }
    } else {
        //相机硬件不可用【一般是模拟器】
        return NO;
    }
}


/// 延时操作
- (void)performAfterTimeInterval:(NSTimeInterval )timeInterval action:(void (^)(void))action
{
    double delayInSeconds = timeInterval;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        action();
    });
    
}

#pragma mark ============ 错误处理 ============
- (void)showError:(NSString*)str {
    [self showError:str andTitle:@"提示"];
}

- (void)showError:(NSString*)str andTitle:(NSString *)title
{
    [self.session stopRunning];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:str preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = ({
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.session startRunning];
        }];
        action;
    });
    [alert addAction:action1];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
